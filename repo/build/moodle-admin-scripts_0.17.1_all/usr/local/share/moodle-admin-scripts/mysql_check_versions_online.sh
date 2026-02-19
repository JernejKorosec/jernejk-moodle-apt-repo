#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="fetch available online MySQL versions."
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

# Script: check_mysql_online_versions.sh
# Purpose: List available MySQL Community Server versions from official site

URL="https://dev.mysql.com/downloads/mysql/"

echo "Fetching MySQL Community Server versions from $URL ..."

versions=$(curl -s "$URL" | grep -oP '(?<=MySQL Community Server )([0-9]+\.[0-9]+\.[0-9]+)') 

if [ -z "$versions" ]; then
    echo "No versions found or unable to fetch."
    exit 1
fi

echo "Available MySQL versions:"
echo "$versions" | sort -u
