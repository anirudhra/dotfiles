#!/bin/bash
# (c) Anirudh Acharya
# macOS GPU performance statistics query & live monitor
#
# Usage:
#   ./gpu.sh             # Snapshot of current GPU stats
#   ./gpu.sh -w          # Watch mode (updates every 3 seconds)
#   ./gpu.sh -w 1        # Watch mode with custom interval (e.g. 1 second)

set -euo pipefail

WATCH=false
INTERVAL=3

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -w, --watch [SEC]  Continuously monitor GPU statistics (default interval: 3s).
  -h, --help         Show this help message.

Examples:
  $(basename "$0")         # Query current GPU statistics once
  $(basename "$0") -w      # Live monitor updating every 3 seconds
  $(basename "$0") -w 1    # Live monitor updating every 1 second
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--watch)
      WATCH=true
      if [[ $# -ge 2 && "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        INTERVAL="$2"
        shift
      fi
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        WATCH=true
        INTERVAL="$1"
      else
        echo "Unknown option: $1" >&2
        show_help
        exit 1
      fi
      ;;
  esac
  shift
done

get_gpu_stats() {
  ioreg -l | grep \"PerformanceStatistics\" | cut -d '{' -f 2 | tr '|' ',' | tr -d '}' | tr ',' '\n' | grep -E 'Temp|Fan|Power|Clock|Utilization|%|\(W\)|Hz' || true
}

if [ "$WATCH" = false ]; then
  get_gpu_stats
else
  # Display immediately on startup without initial delay
  while true; do
    clear
    echo "=== macOS GPU Monitor (Interval: ${INTERVAL}s | Ctrl+C to exit) ==="
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
    echo "------------------------------------------------------------------"
    get_gpu_stats
    sleep "$INTERVAL"
  done
fi
