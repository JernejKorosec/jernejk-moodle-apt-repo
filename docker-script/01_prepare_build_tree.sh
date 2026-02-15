#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG (copy from 00_config.env.example)"; exit 1; }
source "$CFG"

SCRIPTS_DIR="${SCRIPTS_DIR:-release}"
SRC_DIR="$REPO_ROOT/scripts/$SCRIPTS_DIR"
[[ -d "$SRC_DIR" ]] || { echo "Missing scripts directory: $SRC_DIR"; exit 1; }

BUILD_DIR="$REPO_ROOT/build/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}"
DATA_DIR="$BUILD_DIR/usr/local/share/$PKG_NAME"
BIN_DIR="$BUILD_DIR/usr/local/bin"
DEBIAN_DIR="$BUILD_DIR/DEBIAN"

mkdir -p "$DATA_DIR" "$BIN_DIR" "$DEBIAN_DIR"

cp "$SRC_DIR/"*.sh "$DATA_DIR/"
chmod 755 "$DATA_DIR/"*.sh

cat > "$DEBIAN_DIR/control" <<EOF
Package: $PKG_NAME
Version: $PKG_VERSION
Section: $PKG_SECTION
Priority: $PKG_PRIORITY
Architecture: $PKG_ARCH
Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
Depends: $PKG_DEPENDS
Description: Moodle/Apache/MySQL/PHP admin helper scripts
 Script bundle for Moodle environment administration and migration tasks.
EOF

for f in "$DATA_DIR"/*.sh; do
  base="$(basename "$f" .sh)"
  ln -sf "../share/$PKG_NAME/$(basename "$f")" "$BIN_DIR/$base"
done

echo "Prepared: $BUILD_DIR"
