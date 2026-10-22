#!/bin/bash
set -Eeuo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="/root"
umask 022

LRCUP="/opt/lrcup/bin/lrcup"
STATE_DIR="/var/lib/lrcup"
LOG_DIR="/var/log/lrcup"
LOG_RETENTION_DAYS=14

if (( $# < 1 || $# > 2 )); then
    echo "Usage: $0 MUSIC_DIRECTORY [REQUIRED_MOUNT_POINT]" >&2
    exit 2
fi

MUSIC_DIR="$1"
REQUIRED_MOUNT="${2:-}"

mkdir -p "$STATE_DIR" "$LOG_DIR"

# One run at a time on this machine/container.
exec 9>"$STATE_DIR/fetch-lyrics.lock"
if ! flock -n 9; then
    echo "Another lyrics job is running; skipping."
    exit 0
fi

LOG_FILE="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S)-$$.log"
DIR_LIST=""

# Preserve original stderr for a failure notification.
exec 3>&2
exec >>"$LOG_FILE" 2>&1

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*"
}

cleanup() {
    local status=$?
    trap - EXIT

    if [[ -n "$DIR_LIST" ]]; then
        rm -f -- "$DIR_LIST" || true
    fi

    log "Finished with exit status $status."

    if (( status != 0 )); then
        printf 'Lyrics job failed; see %s\n' "$LOG_FILE" >&3
    fi

    exit "$status"
}
trap cleanup EXIT

log "Starting lyrics job for: $MUSIC_DIR"

find "$LOG_DIR" -maxdepth 1 -type f \
    -name 'run-*.log' -mtime +"$LOG_RETENTION_DAYS" -delete

[[ -x "$LRCUP" ]] || {
    log "ERROR: Missing executable: $LRCUP"
    exit 1
}

if [[ -n "$REQUIRED_MOUNT" ]] &&
   ! mountpoint -q -- "$REQUIRED_MOUNT"; then
    log "ERROR: Required mount is unavailable: $REQUIRED_MOUNT"
    exit 1
fi

[[ "$MUSIC_DIR" = /* ]] || {
    log "ERROR: Supply an absolute music directory path."
    exit 1
}

[[ -d "$MUSIC_DIR" && -r "$MUSIC_DIR" && -x "$MUSIC_DIR" ]] || {
    log "ERROR: Music directory is missing or inaccessible."
    exit 1
}

MUSIC_DIR="$(realpath -e -- "$MUSIC_DIR")"

DIR_LIST="$(mktemp "$STATE_DIR/directories.XXXXXX")"

# Discover album/track directories, safely handling unusual filenames.
if ! find "$MUSIC_DIR" -type f \( \
    -iname '*.mp3' -o \
    -iname '*.flac' -o \
    -iname '*.m4a' -o \
    -iname '*.ogg' -o \
    -iname '*.opus' -o \
    -iname '*.wav' -o \
    -iname '*.aiff' -o \
    -iname '*.aif' -o \
    -iname '*.aac' -o \
    -iname '*.wma' \
    \) -printf '%h\0' | sort -zu >"$DIR_LIST"; then
    log "ERROR: Could not enumerate the library."
    exit 1
fi

processed=0
failed=0

while IFS= read -r -d '' directory; do
    log "Processing: $directory"

    if [[ ! -w "$directory" ]]; then
        log "ERROR: Directory is not writable: $directory"
        failed=$((failed + 1))
        continue
    fi

    # Sidecars only. Do not embed or force replacement.
    if "$LRCUP" autosearch --download "$directory"; then
        processed=$((processed + 1))
    else
        log "ERROR: lrcup failed for: $directory"
        failed=$((failed + 1))
    fi

    sleep 2
done <"$DIR_LIST"

log "Directories completed: $processed; failed: $failed"

if (( processed == 0 && failed == 0 )); then
    log "WARNING: No matching audio files found; check the path."
fi

if (( failed > 0 )); then
    exit 1
fi
