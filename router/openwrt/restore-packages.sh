#!/bin/sh
# Restore packages marked "overlay" in an OpenWrt package backup.
# Usage: restore-packages.sh [installed_packages.txt]

set -eu

case "${1:-}" in
-h | --help)
  echo "Usage: $0 [installed_packages.txt]"
  echo "Default: /etc/backup/installed_packages.txt"
  exit 0
  ;;
esac

[ "$#" -le 1 ] || {
  echo "Usage: $0 [installed_packages.txt]" >&2
  exit 1
}

FILE="${1:-/etc/backup/installed_packages.txt}"

command -v apk >/dev/null 2>&1 || {
  echo "ERROR: apk is not installed or not in PATH." >&2
  exit 1
}

[ -r "$FILE" ] || {
  echo "ERROR: Cannot read $FILE" >&2
  exit 1
}

# Handle CRLF, select overlay entries, strip the marker, deduplicate.
PACKAGES="$(
  sed 's/\r$//' "$FILE" |
    sed -n 's/[[:space:]]*overlay[[:space:]]*$//p' |
    sed '/^[[:space:]]*$/d' |
    sort -u
)"

[ -n "$PACKAGES" ] || {
  echo "No overlay packages found in $FILE."
  exit 0
}

# Disable pathname expansion before splitting package names.
set -f
set -- $PACKAGES

for pkg; do
  case "$pkg" in
  -* | *[!a-zA-Z0-9._+-]*)
    echo "ERROR: Invalid package name: $pkg" >&2
    exit 1
    ;;
  esac
done

printf '\nOpenWrt overlay package restore\n'
printf '==============================\n'
printf 'Backup file: %s\n\n' "$FILE"

cat <<'INFO'
This script reads package names from your saved installed-package list.

  - Only entries ending in "overlay" are selected.
  - Entries ending in "rom" are excluded.
  - The trailing "overlay" marker is removed before installation.

The backup contains package names, not package installation files.
APK will obtain the selected packages and any required dependencies
from the repositories currently configured on this router.

This restores the selected package names, not their old versions.
It does not restore configuration files or run a blanket apk upgrade.
INFO

printf '\nSelected packages (%s):\n' "$#"
printf '  %s\n' "$@"

printf '\nAfter confirmation, this script will run:\n'
printf '  apk update\n'
printf '  apk add'
printf ' %s' "$@"
printf '\n\n'

# Read from the terminal so redirected input cannot approve installation.
if ! (: </dev/tty) 2>/dev/null; then
  echo "ERROR: An interactive terminal is required for confirmation." >&2
  exit 1
fi

trap 'printf "\nCancelled. No installation started.\n"; exit 130' INT
printf 'Proceed with installation? [y/N] ' >/dev/tty

ANSWER=
if ! IFS= read -r ANSWER </dev/tty; then
  echo
  echo "Cancelled. No installation started."
  exit 0
fi

case "$ANSWER" in
y | Y | yes | YES | Yes)
  ;;
*)
  echo "Cancelled. No installation started."
  exit 0
  ;;
esac

# Restore normal interrupt handling once installation starts.
trap - INT

printf '\nRefreshing APK repository indexes...\n'
apk update

printf '\nInstalling selected packages...\n'
apk add "$@"

printf '\nPackage restore completed.\n'
