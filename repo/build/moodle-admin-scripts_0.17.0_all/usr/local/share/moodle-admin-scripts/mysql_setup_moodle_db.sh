#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="create Moodle database and user/grants."
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

# Filename: setup_moodle_db.sh
# Purpose: Create Moodle database and user in MySQL with timestamped logging

# Exit on error
set -e

# Get script name without extension
SCRIPT_NAME=$(basename "$0" .sh)
# Create timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Log file
LOG_FILE="${SCRIPT_NAME}_${TIMESTAMP}.log"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Starting Moodle database setup script..."

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_FILE="$SCRIPT_DIR/mysql_setup_moodle_db.env"

# Defaults (safe/non-secret)
DB_NAME="${DB_NAME:-moodle}"
DB_USER="${DB_USER:-moodleuser}"
DB_PASS="${DB_PASS:-}"
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS:-}"
ROOT_PASS_FILE="${ROOT_PASS_FILE:-mysql_root.txt}"

# Optional local config (not committed): mysql_setup_moodle_db.env
if [[ -f "$CFG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CFG_FILE"
fi

# Prompt for missing values
if [[ -z "$DB_NAME" ]]; then
    read -r -p "Database name [moodle]: " DB_NAME
    DB_NAME="${DB_NAME:-moodle}"
fi
if [[ -z "$DB_USER" ]]; then
    read -r -p "Database user [moodleuser]: " DB_USER
    DB_USER="${DB_USER:-moodleuser}"
fi
if [[ -z "$DB_PASS" ]]; then
    read -r -s -p "Database user password (input hidden): " DB_PASS
    echo
fi

# Read MySQL root password (from env or file, then prompt)
if [[ -z "$MYSQL_ROOT_PASS" && -f "${SCRIPT_DIR}/${ROOT_PASS_FILE}" ]]; then
    MYSQL_ROOT_PASS=$(<"${SCRIPT_DIR}/${ROOT_PASS_FILE}")
fi
if [[ -z "$MYSQL_ROOT_PASS" ]]; then
    read -r -s -p "MySQL root password (input hidden): " MYSQL_ROOT_PASS
    echo
fi

echo "[$(date)] Creating Moodle database and user..."

# SQL commands to run
SQL=$(cat <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
)

# Execute SQL commands as root
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "$SQL"

echo "[$(date)] Database '${DB_NAME}' and user '${DB_USER}' created successfully."
echo "[$(date)] Moodle database setup is complete. Log saved to $LOG_FILE"
