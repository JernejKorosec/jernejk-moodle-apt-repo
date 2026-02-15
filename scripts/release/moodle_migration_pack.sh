#!/usr/bin/env bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="pack Moodle for migration."
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
Usage: moodle_migration_pack.sh [options]

Options:
  --config PATH          Path to Moodle config.php (preferred).
  --settings PATH        Path to settings file from moodle_detect.sh (overrides auto-detect).
  --dirroot PATH         Moodle code directory (if --config not given).
  --dataroot PATH        Moodle data directory (if not in config.php).
  --target-moodle VER    Target Moodle version (e.g., 3.11, 4.2, 5.0).
  --out DIR              Output directory for archives (default: ./moodle_migration_YYYYMMDD_HHMMSS).
  --skip-db-dump         Skip database dump.
  --help                 Show this help.

Examples:
  ./moodle_migration_pack.sh --config /var/www/moodle/config.php --target-moodle 4.2
  ./moodle_migration_pack.sh --dirroot /var/www/moodle --dataroot /var/moodledata --skip-db-dump
USAGE
}

CONFIG_PATH=""
SETTINGS_PATH=""
DIRROOT=""
DATAROOT=""
TARGET_MOODLE=""
OUT_DIR=""
DO_DB_DUMP="yes"

CLI_CONFIG_PATH=""
CLI_DIRROOT=""
CLI_DATAROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CLI_CONFIG_PATH="$2"; shift 2;;
    --settings) SETTINGS_PATH="$2"; shift 2;;
    --dirroot) CLI_DIRROOT="$2"; shift 2;;
    --dataroot) CLI_DATAROOT="$2"; shift 2;;
    --target-moodle) TARGET_MOODLE="$2"; shift 2;;
    --out) OUT_DIR="$2"; shift 2;;
    --skip-db-dump) DO_DB_DUMP="no"; shift;;
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

CONFIG_PATH="${CLI_CONFIG_PATH:-${CONFIG_PATH:-}}"
DIRROOT="${CLI_DIRROOT:-${DIRROOT:-}}"
DATAROOT="${CLI_DATAROOT:-${DATAROOT:-}}"

if ! command -v php >/dev/null 2>&1; then
  echo "ERROR: php CLI is required to read Moodle config/version files." >&2
  exit 1
fi

find_config() {
  if [[ -n "$CONFIG_PATH" ]]; then
    echo "$CONFIG_PATH"
    return 0
  fi
  if [[ -n "$DIRROOT" && -f "$DIRROOT/config.php" ]]; then
    echo "$DIRROOT/config.php"
    return 0
  fi
  if [[ -f "./config.php" ]]; then
    echo "./config.php"
    return 0
  fi
  for p in /var/www/moodle /var/www/html/moodle /srv/moodle /opt/moodle; do
    if [[ -f "$p/config.php" ]]; then
      echo "$p/config.php"
      return 0
    fi
  done
  return 1
}

CONFIG_PATH="${CONFIG_PATH:-$(find_config || true)}"
if [[ -z "$CONFIG_PATH" || ! -f "$CONFIG_PATH" ]]; then
  echo "ERROR: Could not locate config.php. Provide --config or --dirroot." >&2
  exit 1
fi

php_extract_cfg() {
  local key="$1"
  php -r '
    $config = @file_get_contents($argv[1]);
    if ($config === false) { exit(1); }
    $key = preg_quote($argv[2], "/");
    $patterns = [
      "/\\$CFG->".$key."\\s*=\\s*\\\"([^\\\"]+)\\\"/i",
      "/\\$CFG->".$key."\\s*=\\s*\\x27([^\\x27]+)\\x27/i",
    ];
    foreach ($patterns as $p) {
      if (preg_match($p, $config, $m)) { echo $m[1]; exit(0); }
    }
    exit(1);
  ' "$CONFIG_PATH" "$key" 2>/dev/null
}

DIRROOT="${DIRROOT:-$(php_extract_cfg dirroot || true)}"
DATAROOT="${DATAROOT:-$(php_extract_cfg dataroot || true)}"
DBTYPE="$(php_extract_cfg dbtype || true)"
DBHOST="$(php_extract_cfg dbhost || true)"
DBNAME="$(php_extract_cfg dbname || true)"
DBUSER="$(php_extract_cfg dbuser || true)"
DBPASS="$(php_extract_cfg dbpass || true)"

if [[ -z "$DIRROOT" || ! -d "$DIRROOT" ]]; then
  echo "ERROR: Moodle dirroot not found. Provide --dirroot." >&2
  exit 1
fi
if [[ -z "$DATAROOT" || ! -d "$DATAROOT" ]]; then
  echo "ERROR: Moodle dataroot not found. Provide --dataroot." >&2
  exit 1
fi

VERSION_PHP="$DIRROOT/version.php"
if [[ ! -f "$VERSION_PHP" ]]; then
  echo "ERROR: version.php not found under $DIRROOT." >&2
  exit 1
fi

read_version_field() {
  local field="$1"
  php -r '
    $content = @file_get_contents($argv[1]);
    if ($content === false) { exit(1); }
    $field = preg_quote($argv[2], "/");
    if (preg_match("/\\$".$field."\\s*=\\s*\\x27([^\\x27]+)\\x27/", $content, $m)) {
      echo $m[1]; exit(0);
    }
    exit(1);
  ' "$VERSION_PHP" "$field" 2>/dev/null
}

MOODLE_RELEASE="$(read_version_field release || true)"
MOODLE_BRANCH="$(read_version_field branch || true)"
PHP_VERSION="$(php -r 'echo PHP_VERSION;' 2>/dev/null || true)"

echo "Detected Moodle config: $CONFIG_PATH"
echo "Detected dirroot: $DIRROOT"
echo "Detected dataroot: $DATAROOT"
echo "Detected Moodle release: ${MOODLE_RELEASE:-unknown}"
echo "Detected Moodle branch: ${MOODLE_BRANCH:-unknown}"
echo "Detected PHP version: ${PHP_VERSION:-unknown}"

version_ge() { [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]; }
version_le() { [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ]]; }

check_php_for_target() {
  local target="$1"
  local min="" max=""
  case "$target" in
    3.6) min="7.0"; max="7.4";;
    3.11|4.0) min="7.3"; max="8.0";;
    4.1) min="7.4"; max="8.1";;
    4.2) min="8.0"; max="8.2";;
    4.4) min="8.1"; max="8.3";;
    5.0) min="8.2"; max="8.4";;
    *) return 0;;
  esac
  if [[ -z "$PHP_VERSION" ]]; then
    echo "WARN: Could not determine PHP version."
    return 0
  fi
  if version_ge "$PHP_VERSION" "$min" && version_le "$PHP_VERSION" "$max"; then
    echo "OK: PHP $PHP_VERSION is within Moodle $target range ($min - $max)."
  else
    echo "WARN: PHP $PHP_VERSION is outside Moodle $target range ($min - $max)."
  fi
}

if [[ -n "$TARGET_MOODLE" ]]; then
  echo "Target Moodle version: $TARGET_MOODLE"
  check_php_for_target "$TARGET_MOODLE"
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="./moodle_migration_${TIMESTAMP}"
fi

mkdir -p "$OUT_DIR"

echo "Packaging Moodle code..."
tar -czf "$OUT_DIR/moodle_code.tar.gz" -C "$DIRROOT" .

echo "Packaging moodledata (excluding cache/temp/sessions)..."
tar -czf "$OUT_DIR/moodledata.tar.gz" \
  --exclude="cache" \
  --exclude="localcache" \
  --exclude="sessions" \
  --exclude="temp" \
  --exclude="trashdir" \
  -C "$DATAROOT" .

if [[ "$DO_DB_DUMP" == "yes" ]]; then
  if [[ "$DBTYPE" =~ ^(mariadb|mysqli|mysql)$ ]]; then
    if command -v mysqldump >/dev/null 2>&1; then
      if [[ -n "$DBNAME" && -n "$DBUSER" ]]; then
        echo "Dumping database to $OUT_DIR/moodle_db.sql ..."
        MYSQL_PWD="$DBPASS" mysqldump -h "${DBHOST:-localhost}" -u "$DBUSER" "$DBNAME" > "$OUT_DIR/moodle_db.sql"
      else
        echo "WARN: DB settings missing in config.php; skipping DB dump."
      fi
    else
      echo "WARN: mysqldump not found; skipping DB dump."
    fi
  else
    echo "WARN: Unsupported DB type ($DBTYPE); skipping DB dump."
  fi
else
  echo "Skipping DB dump (per --skip-db-dump)."
fi

echo "Done. Output directory: $OUT_DIR"
