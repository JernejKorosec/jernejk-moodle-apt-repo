#!/usr/bin/env bash
set -euo pipefail

APT_BASE_URL="${APT_BASE_URL:-https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/repo}"
REPO_KEYRING="${REPO_KEYRING:-/usr/share/keyrings/jernejk-moodle-apt-repo.gpg}"
REPO_LIST_FILE="${REPO_LIST_FILE:-/etc/apt/sources.list.d/jernejk-moodle-apt-repo.list}"
PACKAGE_NAME="${PACKAGE_NAME:-moodle-admin-scripts}"
REPO_DIST="${REPO_DIST:-stable}"
REPO_COMPONENT="${REPO_COMPONENT:-main}"
REPO_ARCH="${REPO_ARCH:-all}"

echo "Installing repository key..."
curl -fsSL "$APT_BASE_URL/public.key" \
  | gpg --dearmor \
  | sudo tee "$REPO_KEYRING" >/dev/null

echo "Adding repository source..."
echo "deb [arch=${REPO_ARCH} signed-by=${REPO_KEYRING}] ${APT_BASE_URL} ${REPO_DIST} ${REPO_COMPONENT}" \
  | sudo tee "$REPO_LIST_FILE" >/dev/null

echo "Updating apt index..."
sudo apt update

echo "Installing package: ${PACKAGE_NAME}"
sudo apt install -y "$PACKAGE_NAME"

echo "Done."
