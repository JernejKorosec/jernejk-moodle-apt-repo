#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="switch active PHP version for CLI/Apache FPM."
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
[[ $# -eq 1 ]] || die "Usage: sudo $0 <php_version> (e.g. 7.4, 8.4)"

TARGET="$1"
[[ "$TARGET" =~ ^[0-9]+\.[0-9]+$ ]] || die "Invalid version format: $TARGET"

PHP_BIN="/usr/bin/php${TARGET}"
FPM_SVC="php${TARGET}-fpm"
FPM_SOCK="/run/php/php${TARGET}-fpm.sock"
APACHE_CONF="php${TARGET}-fpm"

echo "=== Switch PHP to ${TARGET} (CLI + Apache conf) - NO APACHE START/RESTART/RELOAD ==="

# Validate PHP binary
[[ -x "$PHP_BIN" ]] || die "Missing $PHP_BIN (install php${TARGET}-cli)."
"$PHP_BIN" -v >/dev/null || die "php${TARGET} cannot run."

# Validate FPM service + socket (safe to start FPM)
if ! systemctl list-unit-files --type=service 2>/dev/null | awk '{print $1}' | grep -qx "${FPM_SVC}.service"; then
  if [[ ! -f "/lib/systemd/system/${FPM_SVC}.service" && \
        ! -f "/usr/lib/systemd/system/${FPM_SVC}.service" && \
        ! -f "/etc/systemd/system/${FPM_SVC}.service" && \
        ! -x "/etc/init.d/${FPM_SVC}" ]]; then
    die "Missing ${FPM_SVC} (install php${TARGET}-fpm)."
  fi
fi
systemctl enable --now "${FPM_SVC}" >/dev/null
systemctl is-active --quiet "${FPM_SVC}" || die "${FPM_SVC} not running."
[[ -S "$FPM_SOCK" ]] || die "Missing FPM socket: $FPM_SOCK"

# Ensure Apache is set up for FPM (no start)
command -v a2enmod >/dev/null 2>&1 || die "Apache tools not found (a2enmod)."

# Disable mod_php if present
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

# Switch CLI via update-alternatives
MAJOR="${TARGET%.*}"
MINOR="${TARGET#*.}"
PRIO=$(( MAJOR * 100 + MINOR ))

ensure_alt () {
  local name="$1" link="$2" path="$3" priority="$4"
  [[ -x "$path" ]] || return 0
  update-alternatives --install "$link" "$name" "$path" "$priority" >/dev/null
}

ensure_alt php        /usr/bin/php        "/usr/bin/php${TARGET}"        "$PRIO"
ensure_alt phar       /usr/bin/phar       "/usr/bin/phar${TARGET}"       "$PRIO"
ensure_alt phar.phar  /usr/bin/phar.phar  "/usr/bin/phar.phar${TARGET}"  "$PRIO"
ensure_alt phpize     /usr/bin/phpize     "/usr/bin/phpize${TARGET}"     "$PRIO"
ensure_alt php-config /usr/bin/php-config "/usr/bin/php-config${TARGET}" "$PRIO"

update-alternatives --set php "$PHP_BIN" >/dev/null
[[ -x "/usr/bin/phar${TARGET}" ]]       && update-alternatives --set phar "/usr/bin/phar${TARGET}" >/dev/null || true
[[ -x "/usr/bin/phar.phar${TARGET}" ]]  && update-alternatives --set phar.phar "/usr/bin/phar.phar${TARGET}" >/dev/null || true
[[ -x "/usr/bin/phpize${TARGET}" ]]     && update-alternatives --set phpize "/usr/bin/phpize${TARGET}" >/dev/null || true
[[ -x "/usr/bin/php-config${TARGET}" ]] && update-alternatives --set php-config "/usr/bin/php-config${TARGET}" >/dev/null || true

echo "CLI now: $(php -v | head -n 1)"

# Switch Apache FPM conf (enable target, disable others) — DO NOT reload Apache
[[ -f "/etc/apache2/conf-available/${APACHE_CONF}.conf" ]] || die "Missing Apache FPM conf: /etc/apache2/conf-available/${APACHE_CONF}.conf"

for enabled in /etc/apache2/conf-enabled/php*-fpm.conf; do
  [[ -e "$enabled" ]] || continue
  base="$(basename "$enabled" .conf)"
  if [[ "$base" != "$APACHE_CONF" ]]; then
    a2disconf "$base" >/dev/null || true
  fi
done

a2enconf "$APACHE_CONF" >/dev/null

# Validate Apache syntax (no start)
apache2ctl configtest >/dev/null || die "Apache configtest failed after switching."

echo
echo "OK: Apache is configured to use PHP ${TARGET} via FPM."
echo "Apache was NOT started or reloaded."
echo "Apply the change manually when you want:"
echo "  sudo systemctl start apache2"
echo "or if it is already running:"
echo "  sudo systemctl reload apache2"
