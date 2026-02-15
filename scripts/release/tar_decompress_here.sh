#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="decompress archives in current directory."
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

# Decompress all supported archives found in the current folder.

shopt -s nullglob

archives=(*.tar.xz *.tar.gz *.tar.zst *.zip)

if [[ ${#archives[@]} -eq 0 ]]; then
  echo "No archives found in current folder."
  exit 0
fi

for a in "${archives[@]}"; do
  case "$a" in
    *.tar.xz)
      if ! command -v xz >/dev/null 2>&1; then
        echo "ERROR: xz not found. Install xz-utils." >&2
        exit 1
      fi
      echo "Extracting $a ..."
      tar -x -f "$a"
      ;;
    *.tar.gz)
      echo "Extracting $a ..."
      tar -xzf "$a"
      ;;
    *.tar.zst)
      if ! command -v zstd >/dev/null 2>&1; then
        echo "ERROR: zstd not found. Install zstd." >&2
        exit 1
      fi
      echo "Extracting $a ..."
      zstd -dc "$a" | tar -x
      ;;
    *.zip)
      if ! command -v unzip >/dev/null 2>&1; then
        echo "ERROR: unzip not found. Install unzip." >&2
        exit 1
      fi
      echo "Extracting $a ..."
      unzip -o "$a"
      ;;
  esac
done

echo "Done."
