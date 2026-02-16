#!/usr/bin/env bash
set -euo pipefail

CFG="/docker-script/00_config.env"
PUBKEY_OUT="/repo/public.key"
GPG_HOME="${GNUPGHOME:-/root/.gnupg}"

show_help() {
  cat <<'EOF'
07_gpg_setup.sh

Interactive helper for APT repo signing setup.

Usage:
  bash /docker-script/07_gpg_setup.sh
  bash /docker-script/07_gpg_setup.sh --help

What it does:
  1. Optionally generate a new keypair (robust quick mode)
  2. List secret keys
  3. Ask for key ID/email/fingerprint and resolve it to a fingerprint
  4. Export public key to /repo/public.key
  5. Set GPG_KEY_ID (fingerprint) in /docker-script/00_config.env

Important:
  - Signing requires a secret key (private key) in /root/.gnupg.
  - This script exits with error if no secret key exists.
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

# Best effort only; bind mounts on Windows may still trigger warnings.
mkdir -p "$GPG_HOME"
chmod 700 "$GPG_HOME" 2>/dev/null || true

get_secret_fingerprints() {
  gpg --list-secret-keys --with-colons --fingerprint 2>/dev/null | awk -F: '
    $1=="sec" { want=1; next }
    want && $1=="fpr" { print $10; want=0 }
  '
}

prompt_new_key_inputs() {
  local default_name default_email
  default_name="${MAINTAINER_NAME:-}"
  default_email="${MAINTAINER_EMAIL:-}"

  read -r -p "Real name${default_name:+ [$default_name]}: " REAL_NAME
  REAL_NAME="${REAL_NAME:-$default_name}"
  if [[ -z "${REAL_NAME:-}" ]]; then
    echo "ERROR: Real name is required."
    return 1
  fi

  read -r -p "Email${default_email:+ [$default_email]}: " EMAIL
  EMAIL="${EMAIL:-$default_email}"
  if [[ -z "${EMAIL:-}" ]]; then
    echo "ERROR: Email is required."
    return 1
  fi

  while true; do
    read -r -s -p "Passphrase for new key: " PASSPHRASE
    echo
    read -r -s -p "Repeat passphrase: " PASSPHRASE_CONFIRM
    echo
    if [[ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]]; then
      echo "Passphrases do not match. Try again."
      continue
    fi
    if [[ -z "${PASSPHRASE:-}" ]]; then
      echo "Passphrase cannot be empty."
      continue
    fi
    break
  done

  KEY_UID="$REAL_NAME <$EMAIL>"
}

generate_key_quick() {
  local target_home="$1"
  GNUPGHOME="$target_home" gpgconf --kill gpg-agent >/dev/null 2>&1 || true
  GNUPGHOME="$target_home" gpg --batch --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --quick-generate-key "$KEY_UID" rsa3072 sign 0
}

generate_with_fallback() {
  local tmp_home tmp_secret
  tmp_home="$(mktemp -d /tmp/gnupg-fallback.XXXXXX)"
  chmod 700 "$tmp_home"

  echo "Primary key generation failed. Trying fallback key home: $tmp_home"
  generate_key_quick "$tmp_home"

  tmp_secret="/tmp/gpg-secret-$(date +%s).asc"
  GNUPGHOME="$tmp_home" gpg --batch --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --armor --export-secret-keys "$KEY_UID" > "$tmp_secret"

  gpg --batch --yes --pinentry-mode loopback --passphrase "$PASSPHRASE" --import "$tmp_secret"
  rm -f "$tmp_secret"
  rm -rf "$tmp_home"
}

set -a
source "$CFG"
set +a

echo "Generate new GPG key now? (y/N)"
read -r gen_choice
if [[ "${gen_choice,,}" == "y" || "${gen_choice,,}" == "yes" ]]; then
  prompt_new_key_inputs
  if ! generate_key_quick "$GPG_HOME"; then
    generate_with_fallback
  fi
  unset PASSPHRASE PASSPHRASE_CONFIRM REAL_NAME EMAIL KEY_UID
fi

echo
echo "Available secret keys:"
gpg --list-secret-keys --keyid-format LONG || true
echo

mapfile -t SECRET_FPRS < <(get_secret_fingerprints)
if [[ "${#SECRET_FPRS[@]}" -eq 0 ]]; then
  echo "ERROR: No secret keys found."
  echo "Run this script again and choose 'y' to generate a key, or import one first."
  echo "Example import: gpg --import /repo/your-private-key.asc"
  exit 1
fi

DEFAULT_KEY="${SECRET_FPRS[0]}"
read -r -p "Enter GPG key ID/email/fingerprint to use [default: $DEFAULT_KEY]: " GPG_KEY_INPUT
GPG_KEY_INPUT="${GPG_KEY_INPUT:-$DEFAULT_KEY}"

RESOLVED_FPR="$(gpg --list-secret-keys --with-colons --fingerprint "$GPG_KEY_INPUT" 2>/dev/null | awk -F: '
  $1=="sec" { want=1; next }
  want && $1=="fpr" { print $10; exit }
')"

if [[ -z "${RESOLVED_FPR:-}" ]]; then
  echo "ERROR: '$GPG_KEY_INPUT' did not resolve to a secret key fingerprint."
  echo "List keys with: gpg --list-secret-keys --keyid-format LONG"
  exit 1
fi

mkdir -p /repo
gpg --armor --export "$RESOLVED_FPR" > "$PUBKEY_OUT"
echo "Exported public key: $PUBKEY_OUT"

if grep -q '^GPG_KEY_ID=' "$CFG"; then
  sed -i "s|^GPG_KEY_ID=.*|GPG_KEY_ID=$RESOLVED_FPR|" "$CFG"
else
  printf '\nGPG_KEY_ID=%s\n' "$RESOLVED_FPR" >> "$CFG"
fi

echo "Updated $CFG with GPG_KEY_ID=$RESOLVED_FPR"
echo "Done. Next: bash /docker-script/run_all.sh"
