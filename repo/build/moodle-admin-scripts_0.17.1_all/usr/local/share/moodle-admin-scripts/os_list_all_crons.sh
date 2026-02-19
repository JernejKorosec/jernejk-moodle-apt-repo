#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="list all cron entries."
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

# List all cron jobs for all users and system-wide

echo "=== User cron jobs ==="
for user in $(cut -f1 -d: /etc/passwd); do
    CRON=$(sudo crontab -u "$user" -l 2>/dev/null)
    if [ ! -z "$CRON" ]; then
        echo "---- Cron jobs for user: $user ----"
        echo "$CRON"
        echo
    fi
done

echo "=== System-wide cron jobs ==="
echo "---- /etc/crontab ----"
cat /etc/crontab
echo

echo "---- /etc/cron.d/ ----"
ls -l /etc/cron.d/
for f in /etc/cron.d/*; do
    echo "Contents of $f:"
    cat "$f"
    echo
done

echo "---- /etc/cron.daily/ ----"
ls -l /etc/cron.daily/
echo "---- /etc/cron.hourly/ ----"
ls -l /etc/cron.hourly/
echo "---- /etc/cron.weekly/ ----"
ls -l /etc/cron.weekly/
echo "---- /etc/cron.monthly/ ----"
ls -l /etc/cron.monthly/
