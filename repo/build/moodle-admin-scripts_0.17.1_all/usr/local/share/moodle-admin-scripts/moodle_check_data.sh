#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="check Moodle data directory state."
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
CFG_FILE="$SCRIPT_DIR/moodle_check_data.env"

# Optional local config (not committed): moodle_check_data.env
if [[ -f "$CFG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CFG_FILE"
fi

CONFIG_FILE="${CONFIG_FILE:-}"
if [[ -z "$CONFIG_FILE" ]]; then
  read -r -p "Path to config.php [/var/www/moodle/config.php]: " CONFIG_FILE
  CONFIG_FILE="${CONFIG_FILE:-/var/www/moodle/config.php}"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.php not found at $CONFIG_FILE"
    exit 1
fi

# Extract dataroot path
DATAROOT=$(grep '^\$CFG->dataroot' "$CONFIG_FILE" | cut -d"'" -f2)

if [ -d "$DATAROOT" ]; then
    echo "Moodle data folder found: $DATAROOT"
    echo "Contents (with sizes in MB, excluding cache/temp folders):"
    ls -lh --block-size=M "$DATAROOT" | grep -v -E 'cache|localcache|sessions|temp|trashdir'
else
    echo "Error: Moodle data folder not found at $DATAROOT"
fi
