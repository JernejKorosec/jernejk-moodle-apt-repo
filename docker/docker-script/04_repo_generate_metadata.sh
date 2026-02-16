#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG"; exit 1; }
source "$CFG"

DIST_DIR="$REPO_ROOT/dists/$DIST_CODENAME"
mkdir -p "$DIST_DIR"

cat > "$DIST_DIR/Release" <<EOF
Origin: JernejK
Label: JernejK Moodle Repo
Suite: $DIST_CODENAME
Codename: $DIST_CODENAME
Architectures: $PKG_ARCH
Components: $DIST_COMPONENT
Description: APT repository for Moodle admin scripts
EOF

(cd "$DIST_DIR" && apt-ftparchive release . >> Release)
echo "Generated: $DIST_DIR/Release"
