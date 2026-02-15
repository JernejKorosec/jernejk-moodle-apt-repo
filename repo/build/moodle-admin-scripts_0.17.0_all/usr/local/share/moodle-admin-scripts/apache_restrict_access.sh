#!/bin/bash
# HELP BLOCK (auto)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DESC="restrict Apache site access by IP."
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

# Usage: ./restrict_apache.sh YOUR_IP SITE_CONF_NAME
# Example: ./restrict_apache.sh 123.45.67.89 moodle.conf

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 YOUR_IP SITE_CONF_NAME"
    exit 1
fi

MY_IP=$1
SITE_CONF=$2

SITES_AVAILABLE="/etc/apache2/sites-available"
SITES_ENABLED="/etc/apache2/sites-enabled"

# Backup original site config
sudo cp $SITES_AVAILABLE/$SITE_CONF $SITES_AVAILABLE/${SITE_CONF}.bak

# Add IP restriction for HTTP and HTTPS
sudo sed -i '/<VirtualHost \*:80>/a \\t<Directory \/var\/www\/> \n\t\tRequire ip '$MY_IP'\n\t</Directory>' $SITES_AVAILABLE/$SITE_CONF
sudo sed -i '/<VirtualHost \*:443>/a \\t<Directory \/var\/www\/> \n\t\tRequire ip '$MY_IP'\n\t</Directory>' $SITES_AVAILABLE/$SITE_CONF

# Enable the site if not already
sudo a2ensite $SITE_CONF

# Ensure SSL module is enabled for HTTPS
sudo a2enmod ssl

# Reload Apache to apply changes
sudo systemctl reload apache2

echo "Site $SITE_CONF is now restricted to IP $MY_IP for HTTP and HTTPS."
