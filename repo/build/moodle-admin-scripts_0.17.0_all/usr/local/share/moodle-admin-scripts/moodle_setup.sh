#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="prepare Moodle code/data directories."
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

# Moodle setup script
# Usage: sudo ./setup_moodle.sh MOODLE_URL /path/to/moodle/code /path/to/moodledata

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 MOODLE_URL MOODLE_CODE_DIR MOODLE_DATA_DIR"
    echo "Example: sudo $0 https://moodle.example.com /var/www/moodle /var/moodledata"
    exit 1
fi

MOODLE_URL=$1
MOODLE_CODE_DIR=$2
MOODLE_DATA_DIR=$3
WWW_USER="www-data"

echo "Setting up Moodle with:"
echo "URL: $MOODLE_URL"
echo "Code directory: $MOODLE_CODE_DIR"
echo "Data directory: $MOODLE_DATA_DIR"

# 1. Create Moodle code directory if it doesn't exist
if [ ! -d "$MOODLE_CODE_DIR" ]; then
    sudo mkdir -p "$MOODLE_CODE_DIR"
    echo "Created Moodle code directory."
fi

# 2. Create Moodle data directory if it doesn't exist
if [ ! -d "$MOODLE_DATA_DIR" ]; then
    sudo mkdir -p "$MOODLE_DATA_DIR"
    echo "Created Moodle data directory."
fi

# 3. Set ownership and permissions
sudo chown -R $WWW_USER:$WWW_USER "$MOODLE_CODE_DIR"
sudo chown -R $WWW_USER:$WWW_USER "$MOODLE_DATA_DIR"
sudo chmod 770 "$MOODLE_DATA_DIR"

# 4. Warn if data directory is inside web root
if [[ "$MOODLE_DATA_DIR" == "$MOODLE_CODE_DIR"* ]]; then
    echo "WARNING: Moodle data directory is inside the web root! This is insecure."
fi

# 5. Output next steps for the user
echo ""
echo "Moodle directories are ready."
echo "Please download Moodle into $MOODLE_CODE_DIR, then open $MOODLE_URL in a browser to continue installation."
echo "During installation, set:"
echo "  Moodle directory: $MOODLE_CODE_DIR"
echo "  Data directory: $MOODLE_DATA_DIR"
echo ""
echo "Ensure your web server user ($WWW_USER) has write access to both directories."
