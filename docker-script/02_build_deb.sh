#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG"; exit 1; }
source "$CFG"

BUILD_DIR="$REPO_ROOT/build/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}"
OUT_DEB="$REPO_ROOT/build/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"

dpkg-deb --build "$BUILD_DIR" "$OUT_DEB"
echo "Built: $OUT_DEB"
