#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="configure MySQL server settings."
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

# Filename: configure_mysql.sh
# Purpose: Backup MySQL config and bind MySQL to localhost with timestamped logging

# Exit on any error
set -e

# Get script name without extension
SCRIPT_NAME=$(basename "$0" .sh)
# Create timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Log file
LOG_FILE="${SCRIPT_NAME}_${TIMESTAMP}.log"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1

MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo "[$(date)] Starting MySQL configuration script..."

# Backup the original configuration
echo "[$(date)] Backing up MySQL config..."
sudo cp $MYSQL_CONF "${MYSQL_CONF}.backup_${TIMESTAMP}"
echo "[$(date)] Backup created at ${MYSQL_CONF}.backup_${TIMESTAMP}"

# Change bind-address to 127.0.0.1
echo "[$(date)] Setting bind-address to 127.0.0.1..."
sudo sed -i "s/^bind-address\s*=.*/bind-address = 127.0.0.1/" $MYSQL_CONF

# Restart MySQL to apply changes
echo "[$(date)] Restarting MySQL..."
sudo systemctl restart mysql

echo "[$(date)] Configuration complete. MySQL is now bound to localhost (127.0.0.1)."
echo "[$(date)] Log saved to $LOG_FILE"
