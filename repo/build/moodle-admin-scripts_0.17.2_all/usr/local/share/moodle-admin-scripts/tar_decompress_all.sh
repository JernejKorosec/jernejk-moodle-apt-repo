#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="decompress all archives in target scope."
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

usage() {
  cat <<'USAGE'
Usage: decompress_all.sh <archive_file> [output_dir]

Extracts a single archive created by compress_all.sh.
Defaults:
  output_dir: current directory
USAGE
}

ARCHIVE="${1:-}"
OUT_DIR="${2:-.}"

if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo "ERROR: archive_file is required and must exist." >&2
  usage
  exit 1
fi

mkdir -p "$OUT_DIR"

case "$ARCHIVE" in
  *.tar.xz)
    if ! command -v xz >/dev/null 2>&1; then
      echo "ERROR: xz not found. Install xz-utils." >&2
      exit 1
    fi
    echo "Extracting $ARCHIVE to $OUT_DIR ..."
    tar -x -C "$OUT_DIR" -f "$ARCHIVE"
    ;;
  *.tar.zst)
    if ! command -v zstd >/dev/null 2>&1; then
      echo "ERROR: zstd not found. Install zstd." >&2
      exit 1
    fi
    echo "Extracting $ARCHIVE to $OUT_DIR ..."
    zstd -dc "$ARCHIVE" | tar -x -C "$OUT_DIR"
    ;;
  *.tar.gz)
    echo "Extracting $ARCHIVE to $OUT_DIR ..."
    tar -xzf "$ARCHIVE" -C "$OUT_DIR"
    ;;
  *)
    echo "ERROR: Unsupported archive extension. Use .tar.xz, .tar.zst, or .tar.gz" >&2
    exit 1
    ;;
esac

echo "Done."
