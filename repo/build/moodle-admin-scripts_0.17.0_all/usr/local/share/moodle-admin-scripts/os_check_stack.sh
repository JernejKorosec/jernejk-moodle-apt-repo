#!/bin/sh
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="check server stack/service status."
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

# check_stack.sh — Ubuntu/Debian (dash)
# FULL stack inspection + versions + Moodle

have_cmd() { command -v "$1" >/dev/null 2>&1; }

realpath_cmd() {
  p="$(command -v "$1" 2>/dev/null)" || return 1
  readlink -f "$p" 2>/dev/null || echo "$p"
}

is_installed_pkg() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

svc_active() {
  have_cmd systemctl || return 1
  systemctl list-unit-files 2>/dev/null | awk '{print $1}' | grep -qx "$1" || return 1
  systemctl is-active --quiet "$1"
}

print_kv() { printf "%s: %s\n" "$1" "$2"; }

try_mysql_query() {
  q="$1"
  if have_cmd mysql; then
    mysql -N -B -e "$q" 2>/dev/null && return 0
    have_cmd sudo && sudo -n mysql -N -B -e "$q" 2>/dev/null && return 0
  fi
  if have_cmd mariadb; then
    mariadb -N -B -e "$q" 2>/dev/null && return 0
    have_cmd sudo && sudo -n mariadb -N -B -e "$q" 2>/dev/null && return 0
  fi
  return 1
}

try_psql_query() {
  q="$1"
  if have_cmd psql; then
    psql -At -c "$q" 2>/dev/null && return 0
    have_cmd sudo && sudo -n -u postgres psql -At -c "$q" 2>/dev/null && return 0
  fi
  return 1
}

print_os() {
  echo "OS:"
  [ -r /etc/os-release ] && grep -E '^(NAME|VERSION|ID|VERSION_ID)=' /etc/os-release
  echo
}

# ---------------- WEB SERVERS ----------------
detect_web() {
  echo "Web server detection:"

  if is_installed_pkg apache2 || svc_active apache2.service; then
    echo "- Apache2"
    apache2ctl -v 2>/dev/null | sed 's/^/  /'
    print_kv "  executable" "$(realpath_cmd apache2ctl)"
    echo "  config:"
    [ -f /etc/apache2/apache2.conf ] && echo "    - /etc/apache2/apache2.conf"
    [ -f /etc/apache2/ports.conf ] && echo "    - /etc/apache2/ports.conf"
    [ -d /etc/apache2/sites-enabled ] && echo "    - /etc/apache2/sites-enabled/"
    [ -d /etc/apache2/conf-enabled ] && echo "    - /etc/apache2/conf-enabled/"
  fi

  if is_installed_pkg nginx || svc_active nginx.service; then
    echo "- Nginx"
    nginx -v 2>&1 | sed 's/^/  /'
    print_kv "  executable" "$(realpath_cmd nginx)"
  fi

  if is_installed_pkg lighttpd || svc_active lighttpd.service; then
    echo "- Lighttpd"
    print_kv "  executable" "$(realpath_cmd lighttpd)"
  fi

  if is_installed_pkg caddy || svc_active caddy.service; then
    echo "- Caddy"
    print_kv "  executable" "$(realpath_cmd caddy)"
    [ -f /etc/caddy/Caddyfile ] && echo "  config: /etc/caddy/Caddyfile"
  fi

  echo
}

# ---------------- DATABASES ----------------
detect_db_mysql_mariadb() {
  (is_installed_pkg mariadb-server || svc_active mariadb.service || \
   is_installed_pkg mysql-server || svc_active mysql.service) || return 1

  echo "- MySQL / MariaDB"

  have_cmd mysql && mysql --version | sed 's/^/  /'
  have_cmd mariadb && mariadb --version | sed 's/^/  /'

  print_kv "  server executable" "$(realpath_cmd mysqld)"

  port="$(try_mysql_query "SHOW VARIABLES LIKE 'port';" | awk '{print $2}')"
  bind="$(try_mysql_query "SHOW VARIABLES LIKE 'bind_address';" | awk '{print $2}')"
  sock="$(try_mysql_query "SHOW VARIABLES LIKE 'socket';" | awk '{print $2}')"

  print_kv "  port" "${port:-unknown}"
  print_kv "  bind-address" "${bind:-unknown}"
  [ -n "$sock" ] && print_kv "  socket" "$sock"

  if have_cmd ss && [ -n "$port" ]; then
    ss -ltnp 2>/dev/null | grep ":$port" >/dev/null \
      && print_kv "  listening" "yes (:$port)" \
      || print_kv "  listening" "no"
  fi

  echo "  config:"
  [ -f /etc/mysql/my.cnf ] && echo "    - /etc/mysql/my.cnf"
  [ -d /etc/mysql/mariadb.conf.d ] && echo "    - /etc/mysql/mariadb.conf.d/"
}

detect_db_postgres() {
  (is_installed_pkg postgresql || svc_active postgresql.service) || return 1
  echo "- PostgreSQL"
  psql --version | sed 's/^/  /'
  print_kv "  server executable" "$(realpath_cmd postgres)"
  port="$(try_psql_query "SHOW port;")"
  addr="$(try_psql_query "SHOW listen_addresses;")"
  print_kv "  port" "${port:-unknown}"
  print_kv "  listen_addresses" "${addr:-unknown}"
}

detect_db_sqlite() {
  (is_installed_pkg sqlite3 || have_cmd sqlite3) || return 1
  echo "- SQLite"
  sqlite3 --version | sed 's/^/  /'
}

detect_db_mssql() {
  (is_installed_pkg mssql-server || svc_active mssql-server.service) || return 1
  echo "- Microsoft SQL Server"
  print_kv "  config" "/var/opt/mssql/"
}

check_db() {
  echo "Database detection:"
  detect_db_mysql_mariadb
  detect_db_postgres
  detect_db_sqlite
  detect_db_mssql
  echo
}

# ---------------- PHP ----------------
check_php() {
  echo "PHP:"
  if have_cmd php; then
    php -v | head -n1 | sed 's/^/  /'
    print_kv "  executable" "$(realpath_cmd php)"
    php --ini | sed 's/^/  /'
  else
    echo "  not installed"
  fi
  echo
}

# ---------------- NODE ----------------
check_node() {
  echo "Node.js:"
  if have_cmd node; then
    node -v | sed 's/^/  version /'
    print_kv "  executable" "$(realpath_cmd node)"
  else
    echo "  not installed"
  fi
  echo
}

# ---------------- MOODLE ----------------
check_moodle() {
  echo "Moodle:"
  for d in /var/www/html/moodle /var/www/moodle /srv/moodle; do
    if [ -f "$d/version.php" ]; then
      print_kv "  path" "$d"
      grep -E '^\$release|\$version' "$d/version.php" | sed 's/^/  /'
      echo
      return
    fi
  done
  echo "  not found"
  echo
}

# ---------------- RUN ----------------
print_os
detect_web
check_db
check_php
check_node
check_moodle
