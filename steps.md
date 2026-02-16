# steps.md

## 1. Open terminal in project root
Run all host commands from this folder:
- `jernejk-moodle-apt-repo`

## 2. Prepare release metadata (host)
Edit `commit.ver`:
- `RELEASE_TAG` (example: `v0.18.0`)
- `PKG_VERSION` (example: `0.18.0`)
- `COMMIT_MESSAGE`
- optional push settings

## 3. Start Docker environment (host)
```bat
start.bat
```

## 4. Enter container shell
Use one of these:
```bat
login.bat
```
or:
```powershell
docker compose exec apt-repo bash
```

## 5. Prepare build config inside container
```bash
cp /docker-script/00_config.env.example /docker-script/00_config.env
```

Edit config:
```bash
nano /docker-script/00_config.env
```
Set at minimum:
- `SCRIPTS_DIR=release`
- `RELEASE_TAG=vX.Y.Z`
- `PKG_VERSION=X.Y.Z`
- `MAINTAINER_NAME=Your Name`
- `MAINTAINER_EMAIL=your-email@example.com`
- `GPG_KEY_ID=<your key id>` (empty means signing step is skipped)

## 6. Optional first-time GPG setup
```bash
bash /docker-script/07_gpg_setup.sh
```

## 7. Build package and repo metadata (inside container)
Run in order:
```bash
bash /docker-script/01_prepare_build_tree.sh
bash /docker-script/02_build_deb.sh
bash /docker-script/03_repo_add_package.sh
bash /docker-script/04_repo_generate_metadata.sh
bash /docker-script/05_repo_sign_metadata.sh
bash /docker-script/06_smoke_test.sh
```

Or all at once:
```bash
bash /docker-script/run_all.sh
```
Note: `run_all.sh` runs steps `01` to `06`; `07_gpg_setup.sh` is separate.

## 8. Verify outputs (inside container)
```bash
ls -lah /repo/build
ls -lah /repo/pool/main/m/moodle-admin-scripts
ls -lah /repo/dists/stable
```
You should see:
- `.deb` in `/repo/build`
- package copied to `/repo/pool/...`
- `Packages`, `Packages.gz`, `Release`
- `InRelease` and `Release.gpg` if signing was enabled

## 9. Exit container
```bash
exit
```

## 10. Commit and tag release (host)
```bat
commit_new.bat
```
Optional push behavior is controlled by `commit.ver`.
Use `commit_new.bat --help` for detailed field descriptions and examples.

## 11. Configure Ubuntu client to use your GitHub-hosted APT repo
Replace `<APT_BASE_URL>` with your published URL where `dists/` and `pool/` are reachable.
Note:
- Commands below assume a regular Ubuntu user with `sudo` (usually available by default).
- If you are already `root`, run the same commands without `sudo`.

Install public key:
```bash
curl -fsSL <APT_BASE_URL>/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/jernejk-repo.gpg >/dev/null
```

Add source:
```bash
echo "deb [signed-by=/usr/share/keyrings/jernejk-repo.gpg] <APT_BASE_URL> stable main" | sudo tee /etc/apt/sources.list.d/jernejk.list
```

Update and install:
```bash
sudo apt update
sudo apt install moodle-admin-scripts
```

## 12. Validate installed commands on client
```bash
apache_show_status --help
php_switch_version --help
moodle_setup --help
```
