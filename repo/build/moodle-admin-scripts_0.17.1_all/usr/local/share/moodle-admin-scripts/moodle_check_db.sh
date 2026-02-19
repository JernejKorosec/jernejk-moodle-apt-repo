#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="check Moodle database connectivity/state."
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
CFG_FILE="$SCRIPT_DIR/moodle_check_db.env"

# Optional local config (not committed): moodle_check_db.env
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

# Extract DB details from config.php
DB_NAME=$(grep '^\$CFG->dbname' "$CONFIG_FILE" | cut -d"'" -f2)
DB_USER=$(grep '^\$CFG->dbuser' "$CONFIG_FILE" | cut -d"'" -f2)
DB_PASS=$(grep '^\$CFG->dbpass' "$CONFIG_FILE" | cut -d"'" -f2)

echo "Database: $DB_NAME"
echo "User: $DB_USER"

# Test connection and list tables
mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SHOW TABLES;"
