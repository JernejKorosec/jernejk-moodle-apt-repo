#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="list installed PHP versions (concise by default)."
show_help() {
  cat <<EOF
$SCRIPT_NAME

$SCRIPT_DESC

Usage:
  $SCRIPT_NAME [options]

Options:
  --all     Show each detected PHP binary and its version.

Help options:
  -h, --help, -help, help, ?, -?
EOF
}

case "${1:-}" in
  --all)
    SHOW_ALL=true
    ;;
  -h|--help|-help|help|\?|-\?)
    show_help
    exit 0
    ;;
  *)
    SHOW_ALL=false
    ;;
esac

if $SHOW_ALL; then
  echo "Detected PHP binaries:"
  echo "----------------------"
else
  echo "Installed PHP versions:"
  echo "-----------------------"
fi

found=false
versions=()

shopt -s nullglob

probe_version() {
  local php_bin="$1"
  if command -v timeout >/dev/null 2>&1; then
    timeout 2 "$php_bin" -r 'echo PHP_VERSION;' 2>/dev/null || true
  else
    "$php_bin" -r 'echo PHP_VERSION;' 2>/dev/null || true
  fi
}

for php in /usr/bin/php /usr/bin/php[0-9].[0-9] /usr/local/bin/php /usr/local/bin/php[0-9].[0-9]; do
  [[ -x "$php" && ! -d "$php" ]] || continue

  version="$(probe_version "$php")"
  [[ -n "$version" ]] || continue

  if $SHOW_ALL; then
    echo "$(basename "$php") -> $version"
  else
    versions+=("$version")
  fi
  found=true
done

if ! $found; then
    echo "No PHP binaries found"
elif ! $SHOW_ALL; then
    printf "%s\n" "${versions[@]}" | sort -Vu
fi
