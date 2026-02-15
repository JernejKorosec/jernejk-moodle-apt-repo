#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG"; exit 1; }
source "$CFG"

DIST_DIR="$REPO_ROOT/dists/$DIST_CODENAME"
REL="$DIST_DIR/Release"
[[ -f "$REL" ]] || { echo "Missing Release file: $REL"; exit 1; }

if [[ -z "${GPG_KEY_ID:-}" ]]; then
  echo "GPG_KEY_ID is empty in 00_config.env; skipping signing."
  exit 0
fi

gpg --batch --yes --default-key "$GPG_KEY_ID" -abs -o "$DIST_DIR/Release.gpg" "$REL"
gpg --batch --yes --default-key "$GPG_KEY_ID" --clearsign -o "$DIST_DIR/InRelease" "$REL"

echo "Signed: $DIST_DIR/Release.gpg and $DIST_DIR/InRelease"
