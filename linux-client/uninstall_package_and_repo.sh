#!/usr/bin/env bash
set -euo pipefail

REPO_KEYRING="${REPO_KEYRING:-/usr/share/keyrings/jernejk-moodle-apt-repo.gpg}"
REPO_LIST_FILE="${REPO_LIST_FILE:-/etc/apt/sources.list.d/jernejk-moodle-apt-repo.list}"
PACKAGE_NAME="${PACKAGE_NAME:-moodle-admin-scripts}"

echo "Removing package: ${PACKAGE_NAME}"
if dpkg -s "$PACKAGE_NAME" >/dev/null 2>&1; then
  sudo apt remove -y "$PACKAGE_NAME"
else
  echo "Package ${PACKAGE_NAME} is not installed."
fi

echo "Removing repository list file..."
if [ -f "$REPO_LIST_FILE" ]; then
  sudo rm -f "$REPO_LIST_FILE"
else
  echo "Repository list file not found: ${REPO_LIST_FILE}"
fi

echo "Removing repository keyring..."
if [ -f "$REPO_KEYRING" ]; then
  sudo rm -f "$REPO_KEYRING"
else
  echo "Repository keyring not found: ${REPO_KEYRING}"
fi

echo "Updating apt index..."
sudo apt update

echo "Done."
