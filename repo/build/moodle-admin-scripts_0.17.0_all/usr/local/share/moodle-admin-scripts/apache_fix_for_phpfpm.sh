#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="disable mod_php and prepare Apache for FPM."
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

set -euo pipefail

die(){ echo "ERROR: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "Run with sudo."

echo "=== Apache fix for PHP-FPM (NO START / NO RELOAD) ==="

echo "[1/5] Stopping apache2 if running..."
systemctl stop apache2 2>/dev/null || true

echo "[2/5] Disabling any mod_php modules..."
if [[ -d /etc/apache2/mods-enabled ]]; then
  mapfile -t phpmods < <(
    ls -1 /etc/apache2/mods-enabled 2>/dev/null \
      | grep -E '^php[0-9]+\.[0-9]+\.load$' \
      | sed 's/\.load$//'
  )
  for m in "${phpmods[@]:-}"; do
    echo "  - a2dismod $m"
    a2dismod -f "$m" >/dev/null 2>&1 || true
  done
fi

echo "[3/5] Enabling PHP-FPM Apache plumbing (mpm_event + proxy_fcgi)..."
a2dismod -f mpm_prefork >/dev/null 2>&1 || true
a2enmod mpm_event >/dev/null
a2enmod proxy_fcgi setenvif >/dev/null
a2enmod mime >/dev/null 2>&1 || true

echo "[4/5] Configtest (must pass before you start Apache)..."
apache2ctl configtest >/dev/null || die "apache2ctl configtest FAILED."

echo "[5/5] Done. Apache remains STOPPED."
echo "Start manually when you decide:"
echo "  sudo systemctl start apache2"
