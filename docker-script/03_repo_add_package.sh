#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG"; exit 1; }
source "$CFG"

DEB="$REPO_ROOT/build/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
[[ -f "$DEB" ]] || { echo "Missing package: $DEB"; exit 1; }

POOL_DIR="$REPO_ROOT/pool/main/${PKG_NAME:0:1}/$PKG_NAME"
BIN_DIR="$REPO_ROOT/dists/$DIST_CODENAME/$DIST_COMPONENT/binary-$PKG_ARCH"

mkdir -p "$POOL_DIR" "$BIN_DIR"
cp -f "$DEB" "$POOL_DIR/"

dpkg-scanpackages "$REPO_ROOT/pool" /dev/null > "$BIN_DIR/Packages"
gzip -kf "$BIN_DIR/Packages"

echo "Package copied and Packages index refreshed."
