#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="back up Moodle data directory."
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
CFG_FILE="$SCRIPT_DIR/moodle_backup_moodledata.env"

# Optional local config (not committed): moodle_backup_moodledata.env
if [[ -f "$CFG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CFG_FILE"
fi

# Folder to backup (prompt if not set)
DATA_DIR="${DATA_DIR:-}"
if [[ -z "$DATA_DIR" ]]; then
  read -r -p "Moodle data path [/var/opt/moodledata]: " DATA_DIR
  DATA_DIR="${DATA_DIR:-/var/opt/moodledata}"
fi

# Check if folder exists
if [ ! -d "$DATA_DIR" ]; then
    echo "Error: $DATA_DIR does not exist!"
    exit 1
fi

# Timestamp for archive name
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="moodledata_backup_$TIMESTAMP.tar.gz"

# Current folder where archive will be saved
OUTPUT_DIR=$(pwd)

echo "Creating backup of $DATA_DIR ..."
sudo tar -czf "$OUTPUT_DIR/$ARCHIVE_NAME" -C "$DATA_DIR" .

# Show archive details in MB
echo "Backup completed!"
ls -lh --block-size=M "$OUTPUT_DIR/$ARCHIVE_NAME"
