#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="back up web root files."
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

# Backup /var/www and save archive in the folder you are currently in

# Get current timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Archive name
ARCHIVE_NAME="www_backup_$TIMESTAMP.tar.gz"

# Save current folder
OUTPUT_DIR=$(pwd)

echo "Creating backup archive: $ARCHIVE_NAME ..."
sudo tar -czf "$OUTPUT_DIR/$ARCHIVE_NAME" /var/www

# Show archive details
echo "Backup completed!"
ls -lh "$OUTPUT_DIR/$ARCHIVE_NAME"
