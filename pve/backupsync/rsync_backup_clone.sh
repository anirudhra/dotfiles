#!/bin/sh
# Script to use rsync for backups and cloning disks
# Usage: script.sh [--dry-run] source/ destination/
# Replicates all files inside source directory in destination directory. Leading slash is required.

set -e

if [ "$1" = "--dry-run" ]; then
    DRYRUN="--dry-run"
    shift
else
    DRYRUN=""
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 [--dry-run] source/ destination/"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Source directory '$1' does not exist."
    exit 2
fi

rsync -avxHAXW --progress "$DRYRUN" "$1" "$2"
