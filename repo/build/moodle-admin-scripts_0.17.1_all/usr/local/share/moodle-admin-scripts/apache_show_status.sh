#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="show Apache service status, ports, and vhost configuration."
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

# Require sudo
if [ "$EUID" -ne 0 ]; then
  echo "=========================================="
  echo "WARNING: This script must be run with sudo."
  echo "Please run:"
  echo "  sudo ./apache_show_status.sh"
  echo "=========================================="
  exit 1
fi

APACHE_SVC="apache2"

echo "===== Apache Status ====="
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$APACHE_SVC"; then
    echo "Apache is RUNNING (systemd service: $APACHE_SVC)"
  else
    echo "Apache is NOT running (systemd service: $APACHE_SVC)"
    systemctl --no-pager -l status "$APACHE_SVC" || true
    exit 1
  fi
else
  if pgrep -x apache2 >/dev/null 2>&1 || pgrep -x httpd >/dev/null 2>&1; then
    echo "Apache process appears RUNNING"
  else
    echo "Apache is NOT running"
    exit 1
  fi
fi

echo
echo "===== Listening Ports ====="

pids="$(pgrep -x apache2 2>/dev/null || true)"
if [[ -z "${pids}" ]]; then
  pids="$(pgrep -x httpd 2>/dev/null || true)"
fi

if [[ -n "${pids}" ]]; then
  if command -v ss >/dev/null 2>&1; then
    ss -ltnp | awk -v pids="$pids" '
      BEGIN {
        n=split(pids, a, " ");
        for(i=1;i<=n;i++) want[a[i]]=1;
        print "Proto LocalAddress:Port  Process";
      }
      NR>1 {
        proc=$0;
        if (match(proc, /pid=([0-9]+)/, m)) {
          if (want[m[1]]) {
            printf "%-5s %-22s %s\n", $1, $4, substr(proc, index(proc, "users:"));
          }
        }
      }
    '
  else
    echo "ss not found; trying lsof..."
    if command -v lsof >/dev/null 2>&1; then
      lsof -nP -iTCP -sTCP:LISTEN | awk -v pids="$pids" '
        BEGIN {
          n=split(pids, a, " ");
          for(i=1;i<=n;i++) want[a[i]]=1;
          print "Command PID  Address";
        }
        NR>1 {
          if (want[$2]) {
            printf "%-7s %-5s %s\n", $1, $2, $9;
          }
        }
      '
    else
      echo "Neither ss nor lsof available to show ports."
    fi
  fi
else
  echo "Could not find apache2/httpd PIDs."
fi

echo
echo "===== Virtual Hosts (apache2ctl -S) ====="
if command -v apache2ctl >/dev/null 2>&1; then
  apache2ctl -S 2>&1 | sed 's/^/  /'
else
  echo "apache2ctl not found."
fi

echo
echo "===== Enabled site configs (/etc/apache2/sites-enabled) ====="
if [[ -d /etc/apache2/sites-enabled ]]; then
  ls -1 /etc/apache2/sites-enabled/ | sed 's/^/  /'
else
  echo "  /etc/apache2/sites-enabled not found."
fi

echo
echo "===== VirtualHost blocks found in enabled configs ====="
if [[ -d /etc/apache2/sites-enabled ]]; then
  while IFS= read -r f; do
    echo "  --- $f ---"
    awk '
      BEGIN{in=0}
      /^\s*<VirtualHost/ {in=1; print "    " $0; next}
      in && /^\s*ServerName/ {print "    " $0}
      in && /^\s*ServerAlias/ {print "    " $0}
      in && /^\s*DocumentRoot/ {print "    " $0}
      /^\s*<\/VirtualHost>/ {in=0; print "    " $0 "\n"}
    ' "$f"
  done < <(find /etc/apache2/sites-enabled -type f -name "*.conf")
else
  echo "  No sites-enabled directory found."
fi

