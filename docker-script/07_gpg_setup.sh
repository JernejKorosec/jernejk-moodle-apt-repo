#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
PUBKEY_OUT="/repo/public.key"

show_help() {
  cat <<'EOF'
07_gpg_setup.sh

Interactive helper for APT repo signing setup.

Usage:
  bash /docker-script/07_gpg_setup.sh
  bash /docker-script/07_gpg_setup.sh --help

What it does:
  1. Optionally run gpg --full-generate-key
  2. List secret keys
  3. Ask for key ID or email
  4. Export public key to /repo/public.key
  5. Set GPG_KEY_ID in /docker-script/00_config.env
EOF
}

case "${1:-}" in
  -h|--help|-help|help|\?|-?)
    show_help
    exit 0
    ;;
esac

[[ -f "$CFG" ]] || { echo "Missing $CFG"; exit 1; }

if ! command -v gpg >/dev/null 2>&1; then
  echo "ERROR: gpg not found in container."
  exit 1
fi

echo "Generate new GPG key now? (y/N)"
read -r gen_choice
if [[ "${gen_choice,,}" == "y" || "${gen_choice,,}" == "yes" ]]; then
  gpg --full-generate-key
fi

echo
echo "Available secret keys:"
gpg --list-secret-keys --keyid-format LONG || true
echo

read -r -p "Enter GPG key ID or email to use: " GPG_KEY_ID
if [[ -z "${GPG_KEY_ID:-}" ]]; then
  echo "ERROR: GPG key ID/email is required."
  exit 1
fi

mkdir -p /repo
gpg --armor --export "$GPG_KEY_ID" > "$PUBKEY_OUT"
echo "Exported public key: $PUBKEY_OUT"

if grep -q '^GPG_KEY_ID=' "$CFG"; then
  sed -i "s|^GPG_KEY_ID=.*|GPG_KEY_ID=$GPG_KEY_ID|" "$CFG"
else
  printf '\nGPG_KEY_ID=%s\n' "$GPG_KEY_ID" >> "$CFG"
fi

echo "Updated $CFG with GPG_KEY_ID=$GPG_KEY_ID"
echo "Done. Next: bash /docker-script/run_all.sh"
