#!/usr/bin/env bash
# dev-allocate-ports.sh — Allocate consecutive free ports from a safe pool.
#
# Usage:
#   bash dev-allocate-ports.sh <count>
#   bash dev-allocate-ports.sh 4
#   bash dev-allocate-ports.sh 4 --validate 7100 7101 7102 7103
#
# Modes:
#   allocate (default):
#     Picks <count> consecutive free ports at random from the pool (20000-29999).
#     Prints space-separated ports to stdout.
#
#   --validate <port1> <port2> ...:
#     Checks whether the given ports are all free.
#     Exits 0 if all free, 1 if any is occupied (prints which ones).
#     When a collision is found, automatically allocates a new block
#     and prints it to stdout as a replacement suggestion.
#
# Pool: 20000-29999 (10 000 ports).
#   - Above common dev tool defaults (3000, 5173, 8080…)
#   - Below macOS ephemeral range (49152-65535)
#   - Collision probability with <100 ports in use: ~1% per attempt
#
# Exit codes:
#   0  Success — ports printed to stdout
#   1  Validation failed (ports occupied) — new block printed as suggestion
#   2  Usage error or no free block found after max attempts
#
# Requires: bash 4+, lsof

set -euo pipefail

if ! command -v lsof >/dev/null 2>&1; then
  echo "Error: lsof is required for port allocation but was not found." >&2
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Install: brew install lsof" >&2
  else
    echo "Install: sudo apt install lsof" >&2
  fi
  exit 2
fi

POOL_START=20000
POOL_END=29999
MAX_ATTEMPTS=50

_port_free() {
  ! lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

_find_free_block() {
  local count="$1"
  local pool_size=$((POOL_END - POOL_START - count + 1))
  local attempt=0

  while ((attempt < MAX_ATTEMPTS)); do
    local base=$((RANDOM % pool_size + POOL_START))
    local all_free=true

    for ((i = 0; i < count; i++)); do
      if ! _port_free $((base + i)); then
        all_free=false
        break
      fi
    done

    if $all_free; then
      local ports=()
      for ((i = 0; i < count; i++)); do
        ports+=($((base + i)))
      done
      echo "${ports[*]}"
      return 0
    fi

    ((attempt++))
  done

  echo "Error: no free block of $count consecutive ports found after $MAX_ATTEMPTS attempts" >&2
  return 2
}

_validate_ports() {
  local count="$1"
  shift
  local ports=("$@")
  local errors=0

  for port in "${ports[@]}"; do
    if ! _port_free "$port"; then
      echo "OCCUPIED=$port PROCESS=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | head -1)" >&2
      ((errors++)) || true
    fi
  done

  if ((errors > 0)); then
    echo "# $errors port(s) occupied — suggested replacement:" >&2
    _find_free_block "$count"
    return 1
  fi

  echo "${ports[*]}"
  return 0
}

# --- main ---

if [[ $# -lt 1 ]]; then
  echo "Usage: dev-allocate-ports.sh <count> [--validate <port1> <port2> ...]" >&2
  exit 2
fi

count="$1"
shift

if ! [[ "$count" =~ ^[0-9]+$ ]] || ((count < 1 || count > 20)); then
  echo "Error: count must be a number between 1 and 20" >&2
  exit 2
fi

if [[ "${1:-}" == "--validate" ]]; then
  shift
  if [[ $# -ne "$count" ]]; then
    echo "Error: --validate expects exactly $count port(s), got $#" >&2
    exit 2
  fi
  _validate_ports "$count" "$@"
else
  _find_free_block "$count"
fi
