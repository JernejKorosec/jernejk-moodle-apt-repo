#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="${PACKAGE_NAME:-moodle-admin-scripts}"

echo "Updating apt index..."
sudo apt update

echo "Upgrading package: ${PACKAGE_NAME}"
sudo apt install -y --only-upgrade "$PACKAGE_NAME"

echo "Done."
