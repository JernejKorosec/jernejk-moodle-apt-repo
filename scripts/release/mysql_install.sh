#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="install MySQL server packages."
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

# Filename: install_mysql.sh
# Purpose: Update Ubuntu and install MySQL server with timestamped logging

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

echo "[$(date)] Starting MySQL installation script..."

echo "[$(date)] Updating package lists..."
sudo apt update
sudo apt upgrade -y

echo "[$(date)] Installing MySQL server..."
sudo apt install -y mysql-server

echo "[$(date)] MySQL installation complete."
echo "[$(date)] You can verify with: sudo systemctl status mysql"
echo "[$(date)] Log saved to $LOG_FILE"
