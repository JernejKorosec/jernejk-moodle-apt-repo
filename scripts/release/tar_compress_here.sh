#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="compress files in current directory."
show_help() {
  cat <<EOF
$SCRIPT_NAME

$SCRIPT_DESC

Usage:
  $SCRIPT_NAME [options]

Help options:
  -h, --help, -help, help, ?, -?
EOF
}

case "${1:-}" in
  -h|--help|-help|help|\?|-\?)
    show_help
    exit 0
    ;;
esac

set -euo pipefail

# Compress everything in the current folder (recursively),
# excluding this script and the output archive.

SCRIPT_NAME="$(basename "$0")"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="archive_${TS}.tar.xz"

if ! command -v xz >/dev/null 2>&1; then
  echo "ERROR: xz not found. Install xz-utils." >&2
  exit 1
fi

echo "Creating $OUT (xz -9e max compression)..."
tar -c \
  --exclude="./$SCRIPT_NAME" \
  --exclude="./$OUT" \
  -C . . | xz -9e > "$OUT"

echo "Done: $OUT"
