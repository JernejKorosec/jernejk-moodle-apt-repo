#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="list detected PHP binaries and versions."
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


echo "Detected PHP versions:"
echo "----------------------"

found=false

for php in /usr/bin/php* /usr/local/bin/php*; do
    if [[ -x "$php" && ! -d "$php" ]]; then
        version=$("$php" -r 'echo PHP_VERSION;' 2>/dev/null)
        if [[ -n "$version" ]]; then
            echo "$(basename "$php") -> $version"
            found=true
        fi
    fi
done

if ! $found; then
    echo "No PHP binaries found"
fi
