#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="update MySQL APT configuration package."
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

# Script: update_mysql_apt.sh
# Purpose: Uninstall old MySQL APT config and install latest official one

set -e

echo "=== Step 1: Remove any old MySQL APT config package ==="
if dpkg -l | grep -q mysql-apt-config; then
    echo "[*] Found old mysql-apt-config, removing..."
    sudo dpkg -r mysql-apt-config
else
    echo "[*] No old mysql-apt-config found."
fi

echo
echo "=== Step 2: Download latest MySQL APT config package ==="
LATEST_URL="https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb"
echo "[*] Downloading from: $LATEST_URL"
wget "$LATEST_URL" -O /tmp/mysql-apt-config_latest.deb

echo
echo "=== Step 3: Install latest MySQL APT config ==="
sudo dpkg -i /tmp/mysql-apt-config_latest.deb

echo
echo "=== Step 4: Update package lists ==="
sudo apt update

echo
echo "✅ Done. You can now install your preferred MySQL version via APT."
echo "For example: sudo apt install mysql-server"
