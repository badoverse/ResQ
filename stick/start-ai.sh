#!/usr/bin/env bash
# Portable Ollama + offline library for Linux, run from this USB stick.
# Usage:
#   bash start-ai.sh              open the chat + library in the browser
#   bash start-ai.sh terminal     chat in the terminal instead
#   bash start-ai.sh run MODEL    terminal chat with MODEL
#   bash start-ai.sh pull MODEL   download MODEL onto the stick (needs internet)
#   bash start-ai.sh list|rm|show|ps
# AI server: 127.0.0.1:11435 (never clashes with an installed Ollama on 11434).
# Chat page + library: http://127.0.0.1:8090/
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$DIR/ollama/bin/ollama"
KIWIX="$DIR/kiwix/linux/kiwix-serve"
WEB_PORT=8090
export OLLAMA_MODELS="$DIR/models"
export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11435}"
# Ollama looks for its libs in ../lib/ollama relative to the binary; set explicitly too.
export LD_LIBRARY_PATH="$DIR/ollama/lib/ollama${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# Small context keeps RAM use low on modest machines.
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8192}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-30m}"
# Fully local: no Ollama cloud models or cloud features.
export OLLAMA_NO_CLOUD=1
LOG="${TMPDIR:-/tmp}/portable-ollama.log"

PIDS=()
cleanup() { for p in "${PIDS[@]}"; do kill "$p" 2>/dev/null || true; done; }
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
  local zims=("$DIR"/library/*.zim)
  [ -e "${zims[0]}" ] || zims=()
  if [ ! -x "$KIWIX" ]; then chmod +x "$KIWIX" 2>/dev/null || true; fi
  echo "Starting chat page and library on http://127.0.0.1:$WEB_PORT/ ..."
  "$KIWIX" --address=127.0.0.1 --port=$WEB_PORT --customIndex="$DIR/chat.html" "${zims[@]}" \
    >"${TMPDIR:-/tmp}/portable-kiwix.log" 2>&1 &
  PIDS+=($!)
  sleep 2
}

open_browser() {
  local url="http://127.0.0.1:$WEB_PORT/"
  xdg-open "$url" >/dev/null 2>&1 || echo "Open this address in your browser: $url"
}

case "${1:-}" in
  "")
    start_server
    start_web
    open_browser
    echo
    echo "Chat is open in your browser: http://127.0.0.1:$WEB_PORT/"
    read -r -p "Press Enter here to stop the AI and the library... " _
    ;;
  terminal)
    start_server
    mapfile -t MODELS < <("$BIN" list | awk 'NR>1 {print $1}')
    if [ ${#MODELS[@]} -eq 0 ]; then
      echo "No models on the stick. Add one: bash start-ai.sh pull qwen2.5:3b"; exit 1
    fi
    echo "Models on this stick:"
    select M in "${MODELS[@]}"; do [ -n "${M:-}" ] && break; done
    "$BIN" run "$M"
    ;;
  serve)
    exec "$BIN" serve
    ;;
  run|pull|list|rm|show|ps)
    start_server
    "$BIN" "$@"
    ;;
  *)
    echo "Unknown command: $1" >&2; exit 2
    ;;
esac
