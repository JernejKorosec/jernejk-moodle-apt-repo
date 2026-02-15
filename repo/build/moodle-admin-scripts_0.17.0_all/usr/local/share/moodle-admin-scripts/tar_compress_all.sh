#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="compress all files in target scope."
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
Usage: compress_all.sh [options] <source_dir> [output_file]

Creates a single archive with maximum compression.
Defaults:
  output_file: <source_dir_basename>.tar.xz

Options:
  --format xz|zstd|gz   Compression format (default: xz).
  --help               Show this help.
USAGE
}

FORMAT="xz"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2;;
    --help) usage; exit 0;;
    *) break;;
  esac
done

SRC_DIR="${1:-}"
OUT_FILE="${2:-}"

if [[ -z "$SRC_DIR" || ! -d "$SRC_DIR" ]]; then
  echo "ERROR: source_dir is required and must be a directory." >&2
  usage
  exit 1
fi

BASE="$(basename "$SRC_DIR")"

case "$FORMAT" in
  xz)
    OUT_FILE="${OUT_FILE:-${BASE}.tar.xz}"
    if ! command -v xz >/dev/null 2>&1; then
      echo "ERROR: xz not found. Install xz-utils or choose --format gz|zstd." >&2
      exit 1
    fi
    echo "Creating $OUT_FILE using xz -9e (maximum compression)..."
    tar -c -C "$(dirname "$SRC_DIR")" "$BASE" | xz -9e > "$OUT_FILE"
    ;;
  zstd)
    OUT_FILE="${OUT_FILE:-${BASE}.tar.zst}"
    if ! command -v zstd >/dev/null 2>&1; then
      echo "ERROR: zstd not found. Install zstd or choose --format xz|gz." >&2
      exit 1
    fi
    echo "Creating $OUT_FILE using zstd -19 (maximum compression)..."
    tar -c -C "$(dirname "$SRC_DIR")" "$BASE" | zstd -19 -T0 -o "$OUT_FILE"
    ;;
  gz)
    OUT_FILE="${OUT_FILE:-${BASE}.tar.gz}"
    if ! command -v gzip >/dev/null 2>&1; then
      echo "ERROR: gzip not found." >&2
      exit 1
    fi
    echo "Creating $OUT_FILE using gzip -9 (maximum compression)..."
    tar -czf "$OUT_FILE" -C "$(dirname "$SRC_DIR")" "$BASE"
    ;;
  *)
    echo "ERROR: Unknown format: $FORMAT" >&2
    usage
    exit 1
    ;;
esac

echo "Done: $OUT_FILE"
