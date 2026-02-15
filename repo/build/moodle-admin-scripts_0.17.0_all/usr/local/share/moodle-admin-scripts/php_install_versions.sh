#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="install selected PHP versions and dependencies."
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
warn(){ echo "WARN:  $*" >&2; }

[[ $EUID -eq 0 ]] || die "Run with sudo."
[[ $# -eq 1 ]] || die "Usage: sudo $0 <php_version> (e.g. 7.4, 8.4)"

TARGET="$1"
[[ "$TARGET" =~ ^[0-9]+\.[0-9]+$ ]] || die "Invalid version format: $TARGET"

echo "=== PHP multi-version installer (Apache + PHP-FPM) - NO APACHE START/RESTART/RELOAD ==="
echo

apt-get update -y
apt-get install -y --no-install-recommends \
  software-properties-common ca-certificates apt-transport-https lsb-release

# Ensure Ondrej PPA (co-installable PHP versions)
if ! grep -Rq "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
  echo "Adding ppa:ondrej/php ..."
  add-apt-repository -y ppa:ondrej/php
fi
apt-get update -y

echo "Checking PHP ${TARGET} availability in apt..."
apt-cache show "php${TARGET}-cli" >/dev/null 2>&1 || die "PHP ${TARGET} not found in apt."

# Ensure Apache installed (you said you're using Apache)
if ! dpkg -s apache2 >/dev/null 2>&1; then
  echo "Installing apache2..."
  apt-get install -y apache2
fi

# Keep Apache stopped while changing handlers (prevents serving PHP as text)
echo "Stopping Apache to avoid accidental PHP source exposure..."
systemctl stop apache2 2>/dev/null || true

echo "Configuring Apache for PHP-FPM (NO START/RELOAD)..."

# Disable any mod_php modules if present
if [[ -d /etc/apache2/mods-enabled ]]; then
  mapfile -t phpmods < <(
    ls -1 /etc/apache2/mods-enabled 2>/dev/null \
      | grep -E '^php[0-9]+\.[0-9]+\.load$' \
      | sed 's/\.load$//'
  )
  for m in "${phpmods[@]:-}"; do
    a2dismod -f "$m" >/dev/null 2>&1 || true
  done
fi

# Prefer event MPM for FPM
a2dismod -f mpm_prefork >/dev/null 2>&1 || true
a2enmod mpm_event >/dev/null
a2enmod proxy_fcgi setenvif >/dev/null
a2enmod mime >/dev/null 2>&1 || true

pkg_exists() { apt-cache show "$1" >/dev/null 2>&1; }

ensure_sodium_module() {
  local v="$1"
  local phpbin="/usr/bin/php${v}"

  if "$phpbin" -m | grep -qi '^sodium$'; then
    return 0
  fi

  # Some repos offer a generic php-sodium (not versioned). Try it if available.
  if pkg_exists "php-sodium"; then
    apt-get install -y php-sodium
  fi

  # Re-check
  "$phpbin" -m | grep -qi '^sodium$' || die "PHP ${v} does not have the sodium extension enabled."
}

# Moodle-friendly extensions to install for each version.
# Note: sodium is checked as a MODULE, not installed as php${v}-sodium (often not a package).
COMMON_EXT=(
  cli common fpm
  mysql
  xml curl gd intl mbstring soap zip opcache
)

echo
echo "--- Installing PHP ${TARGET} (FPM + extensions) ---"

pkgs=()
for ext in "${COMMON_EXT[@]}"; do
  pkgs+=( "php${TARGET}-${ext}" )
done

for pkg in "${pkgs[@]}"; do
  pkg_exists "$pkg" || die "Package not found: $pkg"
done

apt-get install -y "${pkgs[@]}"

# Start/enable FPM safely (not Apache)
systemctl enable --now "php${TARGET}-fpm" >/dev/null
systemctl is-active --quiet "php${TARGET}-fpm" || die "php${TARGET}-fpm is not running."

sock="/run/php/php${TARGET}-fpm.sock"
[[ -S "$sock" ]] || die "Missing FPM socket for PHP ${TARGET}: $sock"

"/usr/bin/php${TARGET}" -v >/dev/null || die "php${TARGET} cannot run."

ensure_sodium_module "$TARGET"

conf="/etc/apache2/conf-available/php${TARGET}-fpm.conf"
if [[ -f "$conf" ]]; then
  echo "  - Apache FPM conf present: php${TARGET}-fpm"
else
  warn "Missing $conf (switch script expects it)."
fi

echo
echo "Apache syntax check (configtest only)..."
apache2ctl configtest >/dev/null || die "Apache configtest failed."

echo
echo "OK: Installed and validated PHP ${TARGET}"
echo "Apache remains STOPPED (by design). Start it manually when ready:"
echo "  sudo systemctl start apache2"
echo "Then pick which PHP Apache uses:"
echo "  sudo ./php_switch_version.sh 7.4"
