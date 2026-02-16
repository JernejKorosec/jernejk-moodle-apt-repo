# GPG Signing (APT Repo)

## 1) Enter container (from Windows host)
```bat
start.bat
login.bat
```

## 2) Go to docker-script folder inside container
```bash
cd /docker-script
```

## 3) Run helper script
```bash
bash /docker-script/07_gpg_setup.sh
```

What it does:
- lets you generate a new key (optional)
- lists your secret keys
- asks for key ID/email/fingerprint (stores resolved fingerprint)
- exports public key to `/repo/public.key`
- writes `GPG_KEY_ID` into `/docker-script/00_config.env`

## 4) Build and sign repo metadata
```bash
bash /docker-script/run_all.sh
```

## 5) Commit and push
Commit these files:
- `repo/dists/*` (includes `InRelease` and `Release.gpg`)
- `repo/public.key`

## 6) Client side usage
```bash
curl -fsSL <APT_BASE_URL>/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/jernejk-repo.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jernejk-repo.gpg] <APT_BASE_URL> stable main" | sudo tee /etc/apt/sources.list.d/jernejk.list
sudo apt update
sudo apt install moodle-admin-scripts
```
