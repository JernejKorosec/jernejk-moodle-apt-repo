#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="check Moodle code directory state."
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_FILE="$SCRIPT_DIR/moodle_check_code.env"

# Optional local config (not committed): moodle_check_code.env
if [[ -f "$CFG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CFG_FILE"
fi

MOODLE_CODE_DIR="${MOODLE_CODE_DIR:-}"
if [[ -z "$MOODLE_CODE_DIR" ]]; then
  read -r -p "Moodle code path [/var/www/moodle]: " MOODLE_CODE_DIR
  MOODLE_CODE_DIR="${MOODLE_CODE_DIR:-/var/www/moodle}"
fi

if [ -d "$MOODLE_CODE_DIR" ]; then
    echo "Moodle code folder found: $MOODLE_CODE_DIR"
    echo "Contents (with sizes in MB):"
    ls -lh --block-size=M "$MOODLE_CODE_DIR"
else
    echo "Error: Moodle code folder not found at $MOODLE_CODE_DIR"
fi
