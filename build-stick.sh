#!/usr/bin/env bash
# Build a ResQ emergency stick: offline AI assistant + offline library + emergency guides.
#
# Usage:
#   ./build-stick.sh /path/to/mounted/usb-stick [options]
#
# Options:
#   --skip-wikipedia   don't download the full Italian Wikipedia (saves 10.7 GB)
#   --skip-big-models  don't download resq-think:7b and resq-vision:7b (saves 10.7 GB)
#   --skip-android     don't prepare the android/ folder (saves ~4.4 GB)
#   --skip-guides      don't download the Protezione Civile PDF leaflets
#   --keep-cache       keep the download cache (default: deleted at the end)
#
# Runs on Linux x86_64 or macOS. Needs: curl, tar, unzip (+ zstd on Linux).
# Downloads go to a cache on the internal disk first ($RESQ_CACHE, default ~/.cache/resq-build),
# because Ollama downloads straight to exFAT are extremely slow.
set -euo pipefail

OLLAMA_VER=0.32.5
KIWIX_TOOLS_VER=3.8.1
KIWIX_APK_VER=3.13.0
POCKETPAL_VER=1.24.0
ZIM_BASE=https://download.kiwix.org/zim/wikipedia
ZIM_SMALL=(wikipedia_it_medicine_maxi_2026-10.zim wikipedia_en_medicine_maxi_2026-10.zim)
ZIM_WIKI=wikipedia_it_all_nopic_2026-11.zim
GUIDES=(
  "Protezione-Civile_Multirischio_2025.pdf https://eventi.protezionecivile.gov.it/static/c2828dd8a06a45e69e3be33238647783/sfogliabile-multirischio-inr_0.pdf"
  "Terremoto_cosa-sapere.pdf https://prefettura.interno.gov.it/sites/default/files/48/2024-01/pieghevole-io-non-rischio-terremoto_-_cosa_sapere.pdf"
  "Terremoto_cosa-fare.pdf https://prefettura.interno.gov.it/sites/default/files/48/2024-01/pieghevole-io-non-rischio-terremoto_-_cosa_fare.pdf"
  "Alluvione_cosa-sapere.pdf https://prefettura.interno.gov.it/sites/default/files/48/2024-01/pieghevole-io-non-rischio-alluvione-_cosa_sapere.pdf"
  "Alluvione_cosa-fare.pdf https://prefettura.interno.gov.it/sites/default/files/48/2024-01/pieghevole-io-non-rischio-alluvione-cosa_fare.pdf"
  "Alluvione_vademecum.pdf https://prefettura.interno.gov.it/sites/default/files/48/2024-01/io-non-rischio-vademecum_ok.pdf"
  "Maremoto_cosa-fare.pdf https://prefettura.interno.gov.it/sites/default/files/48/2024-01/pieghevole-io-non-rischio-maremoto_-_cosa_fare.pdf"
  "Vulcano_isola-di-Vulcano-Eolie.pdf https://d21tcpckr0ly0r.cloudfront.net/static/3d02037204d3ef4ddffba85c0164e99d/pieghevole-io-non-rischio-vulcano.pdf"
)
ANDROID_MODELS=("resq:1.5b resq-1.5b.gguf" "resq:3b resq-3b.gguf" "resq-think:1.5b resq-think-1.5b.gguf")
BUILD_PORT=11439

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

TARGET=""; SKIP_WIKI=0; SKIP_BIG=0; SKIP_ANDROID=0; SKIP_GUIDES=0; KEEP_CACHE=0
for a in "$@"; do
  case "$a" in
    --skip-wikipedia) SKIP_WIKI=1 ;;
    --skip-big-models) SKIP_BIG=1 ;;
    --skip-android) SKIP_ANDROID=1 ;;
    --skip-guides) SKIP_GUIDES=1 ;;
    --keep-cache) KEEP_CACHE=1 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option $a" ;;
    *) [ -z "$TARGET" ] || die "only one target path allowed"; TARGET="$a" ;;
  esac
done
[ -n "$TARGET" ] || die "give the path of the mounted USB stick. Example: ./build-stick.sh /media/\$USER/RESQ"
[ -d "$TARGET" ] && [ -w "$TARGET" ] || die "$TARGET is not a writable directory"
TARGET="$(cd "$TARGET" && pwd)"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${RESQ_CACHE:-$HOME/.cache/resq-build}"
mkdir -p "$CACHE"

# --- host checks -----------------------------------------------------------
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Linux-x86_64) command -v zstd >/dev/null || die "install zstd first (e.g. sudo apt install zstd / sudo dnf install zstd)" ;;
  Darwin-*) ;;
  *) die "build host must be Linux x86_64 or macOS (this is $OS $ARCH). The finished stick still runs on Windows too." ;;
esac
for c in curl tar unzip; do command -v $c >/dev/null || die "missing tool: $c"; done
if command -v sha256sum >/dev/null; then sha() { sha256sum "$1" | awk '{print $1}'; }; else sha() { shasum -a 256 "$1" | awk '{print $1}'; }; fi

fstype=""
if [ "$OS" = Linux ]; then fstype="$(findmnt -no FSTYPE -T "$TARGET" 2>/dev/null || true)"
else fstype="$(diskutil info "$TARGET" 2>/dev/null | awk -F: '/Type \(Bundle\)/ {gsub(/ /,"",$2); print $2}')"; fi
case "$fstype" in
  exfat) ;;
  vfat|msdos|fat32) die "the stick is FAT32, which can't hold files over 4 GB. Reformat it as exFAT (this erases it)." ;;
  *) echo "WARNING: the stick filesystem is '$fstype'. exFAT is recommended so it works on Windows, Mac and Linux." ;;
esac

need_gb=42   # full build; minimal build ~16 GB
[ $SKIP_WIKI = 1 ] && need_gb=$((need_gb - 11))
[ $SKIP_BIG = 1 ] && need_gb=$((need_gb - 11))
[ $SKIP_ANDROID = 1 ] && need_gb=$((need_gb - 4))
free_gb=$(( $(df -Pk "$TARGET" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
[ "$free_gb" -ge "$need_gb" ] || die "the stick needs about ${need_gb} GB free, it has ${free_gb} GB"
cache_free=$(( $(df -Pk "$CACHE" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
[ "$cache_free" -ge 20 ] || die "the cache disk ($CACHE) needs about 20 GB free, it has ${cache_free} GB"
echo "Building ResQ on $TARGET (${free_gb} GB free, about ${need_gb} GB needed). Cache: $CACHE"

# Download with resume + retries. Kiwix mirrors sometimes drop HTTP/2 streams on big files.
dl() {
  local url="$1" out="$2" i
  for i in 1 2 3 4 5 6; do
    curl -fL --http1.1 --retry 3 -C - -o "$out" "$url" && return 0
    echo "  download interrupted, retrying ($i)..." >&2; sleep 5
  done
  die "could not download $url"
}
verify() {  # verify FILE EXPECTED_SHA256
  [ "$(sha "$1")" = "$2" ] || die "checksum mismatch for $(basename "$1")"
  echo "  checksum OK: $(basename "$1")"
}

# --- 1. stick files --------------------------------------------------------
step "Copying ResQ launchers, chat page and docs"
cp -R "$REPO/stick/." "$TARGET/"
# Windows batch files need CRLF line endings.
perl -pi -e 's/\r?\n/\r\n/' "$TARGET/start-ai.bat"

# --- 2. Ollama for Linux, Windows, macOS ----------------------------------
step "Downloading Ollama $OLLAMA_VER (Linux, Windows, macOS)"
OBASE="https://github.com/ollama/ollama/releases/download/v$OLLAMA_VER"
dl "$OBASE/sha256sum.txt" "$CACHE/ollama-sha256sum.txt"
osum() { awk -v f="./$1" '$2==f {print $1}' "$CACHE/ollama-sha256sum.txt"; }
for f in ollama-linux-amd64.tar.zst ollama-windows-amd64.zip ollama-darwin.tgz; do
  [ -f "$CACHE/$f" ] && [ "$(sha "$CACHE/$f")" = "$(osum $f)" ] || dl "$OBASE/$f" "$CACHE/$f"
  verify "$CACHE/$f" "$(osum $f)"
done
rm -rf "$CACHE/ollama-linux" "$CACHE/ollama-mac"; mkdir -p "$CACHE/ollama-linux" "$CACHE/ollama-mac"
if command -v zstd >/dev/null; then
  zstd -dc "$CACHE/ollama-linux-amd64.tar.zst" | tar -x -C "$CACHE/ollama-linux"
else
  # macOS hosts usually lack zstd; bsdtar can read .tar.zst directly.
  tar -xf "$CACHE/ollama-linux-amd64.tar.zst" -C "$CACHE/ollama-linux" || die "install zstd to unpack the Linux build (brew install zstd)"
fi
tar -xzf "$CACHE/ollama-darwin.tgz" -C "$CACHE/ollama-mac" 2>/dev/null
# exFAT has no symlinks: copy with links resolved.
mkdir -p "$TARGET/ollama/bin" "$TARGET/ollama/lib" "$TARGET/ollama/windows" "$TARGET/ollama/mac"
cp -L "$CACHE/ollama-linux/bin/ollama" "$TARGET/ollama/bin/"
cp -RL "$CACHE/ollama-linux/lib/ollama" "$TARGET/ollama/lib/"
unzip -q -o "$CACHE/ollama-windows-amd64.zip" -d "$TARGET/ollama/windows"
cp -RL "$CACHE/ollama-mac/." "$TARGET/ollama/mac/"

# --- 3. kiwix-serve (offline library + chat page server) -------------------
step "Downloading kiwix-serve $KIWIX_TOOLS_VER"
KBASE="https://download.kiwix.org/release/kiwix-tools"
for pair in linux-x86_64:linux macos-arm64:mac-arm macos-x86_64:mac-intel win-x86_64:windows; do
  plat="${pair%%:*}"; dir="${pair##*:}"; ext=tar.gz; [ "$plat" = win-x86_64 ] && ext=zip
  f="kiwix-tools_${plat}-${KIWIX_TOOLS_VER}.$ext"
  [ -f "$CACHE/$f" ] || dl "$KBASE/$f" "$CACHE/$f"
  mkdir -p "$TARGET/kiwix/$dir"
  if [ "$ext" = zip ]; then
    unzip -tq "$CACHE/$f" >/dev/null || die "$f is damaged"
    rm -rf "$CACHE/kiwix-win"; unzip -q -o "$CACHE/$f" -d "$CACHE/kiwix-win"
    exe="$(find "$CACHE/kiwix-win" -name kiwix-serve.exe | head -1)"
    cp -R "$(dirname "$exe")/." "$TARGET/kiwix/$dir/"
  else
    tar -xzf "$CACHE/$f" -C "$TARGET/kiwix/$dir" --strip-components=1
  fi
  echo "  $dir OK"
done

# --- 4. AI models -----------------------------------------------------------
step "Downloading AI models and creating the ResQ models"
if [ "$OS" = Linux ]; then HOST_OLLAMA="$CACHE/ollama-linux/bin/ollama"; else HOST_OLLAMA="$CACHE/ollama-mac/ollama"; fi
export OLLAMA_MODELS="$CACHE/models" OLLAMA_HOST="127.0.0.1:$BUILD_PORT" OLLAMA_NO_CLOUD=1
mkdir -p "$OLLAMA_MODELS"
"$HOST_OLLAMA" serve >"$CACHE/build-ollama.log" 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT
for _ in $(seq 1 30); do "$HOST_OLLAMA" list >/dev/null 2>&1 && break; sleep 1; done
"$HOST_OLLAMA" list >/dev/null 2>&1 || die "Ollama build server did not start, see $CACHE/build-ollama.log"
SYSTEM_PROMPT="$(cat "$REPO/modelfiles/system-prompt.txt")"
while read -r name base _size group; do
  [ -n "$name" ] || continue
  if [ "$group" = big ] && [ $SKIP_BIG = 1 ]; then echo "  skipping $name"; continue; fi
  echo "  $name  (from $base)"
  "$HOST_OLLAMA" pull "$base" </dev/null
  printf 'FROM %s\nSYSTEM """%s"""\n' "$base" "$SYSTEM_PROMPT" > "$CACHE/Modelfile"
  "$HOST_OLLAMA" create "$name" -f "$CACHE/Modelfile" </dev/null
  "$HOST_OLLAMA" rm "$base" >/dev/null </dev/null   # the model files stay: ResQ uses them
done < <(grep -v '^#' "$REPO/modelfiles/models.txt")
kill $SERVER_PID 2>/dev/null || true; trap - EXIT
echo "  copying models to the stick..."
mkdir -p "$TARGET/models"
cp -R "$CACHE/models/." "$TARGET/models/"

# --- 5. Android -------------------------------------------------------------
if [ $SKIP_ANDROID = 0 ]; then
  step "Preparing the android/ folder"
  mkdir -p "$TARGET/android"
  for pair in "${ANDROID_MODELS[@]}"; do
    name="${pair%% *}"; out="${pair##* }"
    manifest="$CACHE/models/manifests/registry.ollama.ai/library/${name%%:*}/${name##*:}"
    digest="$(grep -o '"mediaType":"application/vnd.ollama.image.model"[^}]*' "$manifest" | grep -o 'sha256:[0-9a-f]*' | head -1)"
    [ -n "$digest" ] || die "could not find the model file for $name"
    cp "$CACHE/models/blobs/${digest/:/-}" "$TARGET/android/$out"
    echo "  $out"
  done
  f="kiwix-$KIWIX_APK_VER.apk"
  [ -f "$CACHE/$f" ] || dl "https://download.kiwix.org/release/kiwix-android/$f" "$CACHE/$f"
  f2="PocketPal-$POCKETPAL_VER.apk"
  [ -f "$CACHE/$f2" ] || dl "https://github.com/a-ghorbani/pocketpal-ai/releases/download/v$POCKETPAL_VER/app-prod-release.apk" "$CACHE/$f2"
  for a in "$f" "$f2"; do unzip -tq "$CACHE/$a" >/dev/null || die "$a is damaged"; cp "$CACHE/$a" "$TARGET/android/"; done
fi

# --- 6. offline library (Kiwix ZIM files) ----------------------------------
step "Downloading the offline library"
mkdir -p "$TARGET/library"
zims=("${ZIM_SMALL[@]}"); [ $SKIP_WIKI = 0 ] && zims+=("$ZIM_WIKI")
for z in "${zims[@]}"; do
  expected="$(curl -fsSL "$ZIM_BASE/$z.sha256" | awk '{print $1}')"
  if [ -f "$TARGET/library/$z" ] && [ "$(sha "$TARGET/library/$z")" = "$expected" ]; then echo "  already there: $z"; continue; fi
  echo "  $z"
  dl "$ZIM_BASE/$z" "$TARGET/library/$z"
  verify "$TARGET/library/$z" "$expected"
done

# --- 7. emergency guides ------------------------------------------------------
if [ $SKIP_GUIDES = 0 ]; then
  step "Downloading Protezione Civile guides"
  mkdir -p "$TARGET/guide"
  for g in "${GUIDES[@]}"; do
    name="${g%% *}"; url="${g##* }"
    if curl -fsSL --retry 3 -m 180 -o "$TARGET/guide/$name" "$url" && head -c 4 "$TARGET/guide/$name" | grep -q '%PDF'; then
      echo "  $name"
    else
      rm -f "$TARGET/guide/$name"; echo "  WARNING: could not download $name (link may have moved)"
    fi
  done
fi

# --- done --------------------------------------------------------------------
sync
if [ $KEEP_CACHE = 0 ] && [ -n "$CACHE" ] && [ "$CACHE" != "$HOME" ] && [ "$CACHE" != "/" ]; then
  step "Deleting the download cache"
  rm -rf -- "$CACHE"
fi
step "ResQ stick ready: $TARGET ($(du -sh "$TARGET" 2>/dev/null | cut -f1) used)"
echo "Start it with start-ai.bat (Windows), start-ai.command (Mac) or start-ai.sh (Linux)."
echo "Eject the stick safely before unplugging."
