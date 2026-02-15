#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="list file and directory sizes."
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

# List all files in current folder with human-readable sizes in MB or GB

# Folder to list (default: current folder)
FOLDER=${1:-$(pwd)}

echo "Listing files in: $FOLDER"

# List files with sizes in human-readable format (MB/GB)
ls -lh --block-size=M "$FOLDER"
