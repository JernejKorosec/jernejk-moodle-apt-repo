#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="check Moodle cron configuration/execution."
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

# check_moodle_cron.sh
# Lists cron jobs for www-data (commonly used for Moodle cron)

echo "Cron jobs for www-data:"
sudo crontab -u www-data -l || echo "No cron jobs found for www-data"
