# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="uninstall MySQL packages and remove data directories."
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

sudo systemctl stop mysql
sudo apt remove --purge mysql-server mysql-client mysql-common
sudo apt autoremove
sudo rm -rf /etc/mysql /var/lib/mysql
