#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG"; exit 1; }
source "$CFG"

DEB="$REPO_ROOT/build/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
[[ -f "$DEB" ]] || { echo "Missing package: $DEB"; exit 1; }

echo "== Package info =="
dpkg-deb -I "$DEB"

echo "== Package contents =="
dpkg-deb -c "$DEB" | head -n 80

echo "Smoke test passed."
