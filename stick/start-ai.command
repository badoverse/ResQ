#!/usr/bin/env bash
# Portable Ollama + offline library for macOS: double-click in Finder,
# or run: bash start-ai.command [terminal | run MODEL | pull MODEL | list]
# AI server: 127.0.0.1:11435 (never clashes with an installed Ollama on 11434).
# Chat page + library: http://127.0.0.1:8090/
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$DIR/ollama/mac/ollama"
if [ "$(uname -m)" = "arm64" ]; then KIWIX="$DIR/kiwix/mac-arm/kiwix-serve"; else KIWIX="$DIR/kiwix/mac-intel/kiwix-serve"; fi
WEB_PORT=8090
export OLLAMA_MODELS="$DIR/models"
export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11435}"
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8192}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-5m}"
# Fully local: no Ollama cloud models or cloud features.
export OLLAMA_NO_CLOUD=1
LOG="${TMPDIR:-/tmp}/portable-ollama.log"

# exFAT has no exec bit on macOS, and files from the internet get quarantined.
chmod +x "$BIN" "$KIWIX" 2>/dev/null || true
xattr -dr com.apple.quarantine "$DIR/ollama/mac" "$DIR/kiwix" 2>/dev/null || true

PIDS=()
cleanup() { for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null || true; done; }
trap cleanup EXIT

server_up() { "$BIN" list >/dev/null 2>&1; }

start_server() {
  if server_up; then return; fi
  echo "Starting portable Ollama on $OLLAMA_HOST ..."
  "$BIN" serve >"$LOG" 2>&1 &
  PIDS+=($!)
  for _ in $(seq 1 30); do server_up && return; sleep 1; done
  echo "Server failed to start. Log: $LOG" >&2
  exit 1
}

start_web() {
  local zims=()
  for z in "$DIR"/library/*.zim; do [ -e "$z" ] && zims+=("$z"); done
  echo "Starting chat page and library on http://127.0.0.1:$WEB_PORT/ ..."
  "$KIWIX" --address=127.0.0.1 --port=$WEB_PORT --customIndex="$DIR/chat.html" ${zims[@]+"${zims[@]}"} \
    >"${TMPDIR:-/tmp}/portable-kiwix.log" 2>&1 &
  PIDS+=($!)
  sleep 2
}

case "${1:-}" in
  "")
    start_server
    start_web
    open "http://127.0.0.1:$WEB_PORT/"
    echo
    echo "Chat is open in your browser: http://127.0.0.1:$WEB_PORT/"
    read -r -p "Press Enter here (or close this window) to stop the AI and the library... " _
    ;;
  terminal)
    start_server
    # macOS ships bash 3.2: no mapfile.
    MODELS=()
    while IFS= read -r m; do MODELS+=("$m"); done < <("$BIN" list | awk 'NR>1 {print $1}')
    if [ ${#MODELS[@]} -eq 0 ]; then
      echo "No models on the stick. Add one: bash start-ai.command pull qwen2.5:3b"; exit 1
    fi
    echo "Models on this stick:"
    select M in "${MODELS[@]}"; do [ -n "${M:-}" ] && break; done
    "$BIN" run "$M"
    ;;
  run|pull|list|rm|show|ps)
    start_server
    "$BIN" "$@"
    ;;
  *)
    echo "Unknown command: $1" >&2; exit 2
    ;;
esac
