#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="list PHP directory/config trees."
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


BASE="/etc/php"

if [ ! -d "$BASE" ]; then
  echo "Directory $BASE does not exist."
  exit 1
fi

# Determine output file (same folder as script, same name + timestamp + .txt)
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH" .sh)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTFILE="$SCRIPT_DIR/${SCRIPT_NAME}_${TIMESTAMP}.txt"

{
  echo "PHP directory tree under $BASE"
  echo "================================"

  # Loop versions first for nicer grouping
  for ver in "$BASE"/*; do
    if [ -d "$ver" ]; then
      echo
      echo "Version: $(basename "$ver")"
      echo "---------------------------"
      find "$ver" | sed "s|$ver|.|"
    fi
  done

} | tee "$OUTFILE"

echo
echo "Output saved to: $OUTFILE"
