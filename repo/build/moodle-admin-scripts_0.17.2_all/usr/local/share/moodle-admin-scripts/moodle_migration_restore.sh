#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="restore Moodle from migration package."
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

usage() {
  cat <<'USAGE'
Usage: moodle_migration_restore.sh [options]

Options:
  --in DIR               Input directory with archives (moodle_code.tar.gz, moodledata.tar.gz, moodle_db.sql).
  --settings PATH        Path to settings file from moodle_detect.sh (overrides auto-detect).
  --dirroot PATH         Target Moodle code directory.
  --dataroot PATH        Target Moodle data directory.
  --wwwroot URL          New site URL (updates config.php).
  --dbhost HOST          DB host (default: localhost).
  --dbname NAME          DB name.
  --dbuser USER          DB user.
  --dbpass PASS          DB password.
  --skip-db-import       Skip database import.
  --skip-config-update   Do not modify config.php.
  --help                 Show this help.

Examples:
  ./moodle_migration_restore.sh --in ./moodle_migration_20260131_210000 \
    --dirroot /var/www/moodle --dataroot /var/moodledata \
    --wwwroot https://moodle.example.com --dbname moodle --dbuser moodle --dbpass secret
USAGE
}

IN_DIR=""
SETTINGS_PATH=""
DIRROOT=""
DATAROOT=""
WWWROOT=""
DBHOST="localhost"
DBNAME=""
DBUSER=""
DBPASS=""
DO_DB_IMPORT="yes"
DO_CONFIG_UPDATE="yes"

CLI_IN_DIR=""
CLI_DIRROOT=""
CLI_DATAROOT=""
CLI_WWWROOT=""
CLI_DBHOST=""
CLI_DBNAME=""
CLI_DBUSER=""
CLI_DBPASS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --in) CLI_IN_DIR="$2"; shift 2;;
    --settings) SETTINGS_PATH="$2"; shift 2;;
    --dirroot) CLI_DIRROOT="$2"; shift 2;;
    --dataroot) CLI_DATAROOT="$2"; shift 2;;
    --wwwroot) CLI_WWWROOT="$2"; shift 2;;
    --dbhost) CLI_DBHOST="$2"; shift 2;;
    --dbname) CLI_DBNAME="$2"; shift 2;;
    --dbuser) CLI_DBUSER="$2"; shift 2;;
    --dbpass) CLI_DBPASS="$2"; shift 2;;
    --skip-db-import) DO_DB_IMPORT="no"; shift;;
    --skip-config-update) DO_CONFIG_UPDATE="no"; shift;;
    --help) usage; exit 0;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$SETTINGS_PATH" && -f "./moodle_detect.env" ]]; then
  SETTINGS_PATH="./moodle_detect.env"
fi

if [[ -n "$SETTINGS_PATH" ]]; then
  if [[ ! -f "$SETTINGS_PATH" ]]; then
    echo "ERROR: settings file not found: $SETTINGS_PATH" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$SETTINGS_PATH"
fi

IN_DIR="${CLI_IN_DIR:-${IN_DIR:-.}}"
DIRROOT="${CLI_DIRROOT:-${DIRROOT:-}}"
DATAROOT="${CLI_DATAROOT:-${DATAROOT:-}}"
WWWROOT="${CLI_WWWROOT:-${WWWROOT:-}}"
DBHOST="${CLI_DBHOST:-${DBHOST:-}}"
DBNAME="${CLI_DBNAME:-${DBNAME:-}}"
DBUSER="${CLI_DBUSER:-${DBUSER:-}}"
DBPASS="${CLI_DBPASS:-${DBPASS:-}}"

if [[ -z "$IN_DIR" || ! -d "$IN_DIR" ]]; then
  echo "ERROR: --in must point to a directory with the migration archives." >&2
  exit 1
fi
if [[ -z "$DIRROOT" ]]; then
  echo "ERROR: --dirroot is required." >&2
  exit 1
fi
if [[ -z "$DATAROOT" ]]; then
  echo "ERROR: --dataroot is required." >&2
  exit 1
fi

CODE_TAR="$IN_DIR/moodle_code.tar.gz"
DATA_TAR="$IN_DIR/moodledata.tar.gz"
DB_SQL="$IN_DIR/moodle_db.sql"

if [[ ! -f "$CODE_TAR" ]]; then
  echo "ERROR: Missing $CODE_TAR" >&2
  exit 1
fi
if [[ ! -f "$DATA_TAR" ]]; then
  echo "ERROR: Missing $DATA_TAR" >&2
  exit 1
fi

mkdir -p "$DIRROOT" "$DATAROOT"

echo "Restoring Moodle code to $DIRROOT ..."
tar -xzf "$CODE_TAR" -C "$DIRROOT"

echo "Restoring moodledata to $DATAROOT ..."
tar -xzf "$DATA_TAR" -C "$DATAROOT"

CONFIG_PATH="$DIRROOT/config.php"
if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "ERROR: config.php not found in $DIRROOT after restore." >&2
  exit 1
fi

if [[ "$DO_CONFIG_UPDATE" == "yes" ]]; then
  if [[ -n "$WWWROOT" ]]; then
    echo "Updating wwwroot in config.php ..."
    sed -i.bak "s|\\$CFG->wwwroot\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->wwwroot = '$WWWROOT'|g" "$CONFIG_PATH"
  fi
  echo "Updating dirroot and dataroot in config.php ..."
  sed -i.bak "s|\\$CFG->dirroot\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->dirroot = '$DIRROOT'|g" "$CONFIG_PATH"
  sed -i.bak "s|\\$CFG->dataroot\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->dataroot = '$DATAROOT'|g" "$CONFIG_PATH"

  if [[ -n "$DBNAME" ]]; then
    sed -i.bak "s|\\$CFG->dbname\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->dbname = '$DBNAME'|g" "$CONFIG_PATH"
  fi
  if [[ -n "$DBUSER" ]]; then
    sed -i.bak "s|\\$CFG->dbuser\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->dbuser = '$DBUSER'|g" "$CONFIG_PATH"
  fi
  if [[ -n "$DBPASS" ]]; then
    sed -i.bak "s|\\$CFG->dbpass\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->dbpass = '$DBPASS'|g" "$CONFIG_PATH"
  fi
  if [[ -n "$DBHOST" ]]; then
    sed -i.bak "s|\\$CFG->dbhost\\s*=\\s*['\\\"][^'\\\"]*['\\\"]|\\$CFG->dbhost = '$DBHOST'|g" "$CONFIG_PATH"
  fi
fi

if [[ "$DO_DB_IMPORT" == "yes" ]]; then
  if [[ ! -f "$DB_SQL" ]]; then
    echo "WARN: Missing $DB_SQL; skipping database import."
  else
    if ! command -v mysql >/dev/null 2>&1; then
      echo "WARN: mysql client not found; skipping database import."
    elif [[ -z "$DBNAME" || -z "$DBUSER" ]]; then
      echo "WARN: DB name/user not provided; skipping database import."
    else
      echo "Importing database from $DB_SQL ..."
      MYSQL_PWD="$DBPASS" mysql -h "$DBHOST" -u "$DBUSER" "$DBNAME" < "$DB_SQL"
    fi
  fi
else
  echo "Skipping DB import (per --skip-db-import)."
fi

echo "Restore complete."
echo "Next: verify permissions, run Moodle upgrade if needed, and update URLs with admin/tool/replace."
