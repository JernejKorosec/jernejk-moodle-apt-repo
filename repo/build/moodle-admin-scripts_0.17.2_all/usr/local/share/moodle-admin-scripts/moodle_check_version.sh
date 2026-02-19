#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="read Moodle version from version.php."
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
CFG_FILE="$SCRIPT_DIR/moodle_check_version.env"

# Optional local config (not committed): moodle_check_version.env
if [[ -f "$CFG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CFG_FILE"
fi

MOODLE_PATH="${MOODLE_PATH:-}"
if [[ -z "$MOODLE_PATH" ]]; then
  read -r -p "Moodle root path [/var/www/moodle]: " MOODLE_PATH
  MOODLE_PATH="${MOODLE_PATH:-/var/www/moodle}"
fi

# Check in public folder first (newer Moodle)
VERSION_FILE="$MOODLE_PATH/public/version.php"

# Fallback to old location (older Moodle)
if [ ! -f "$VERSION_FILE" ]; then
    VERSION_FILE="$MOODLE_PATH/version.php"
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "version.php not found in Moodle installation"
    exit 1
fi

# Extract version string
VERSION=$(grep "\$release" "$VERSION_FILE" | cut -d"'" -f2)

echo "Moodle version: $VERSION"
