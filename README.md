# jernejk-moodle-apt-repo
APT repository workspace for building and publishing Debian (`.deb`) packages (Ubuntu/Debian), focused on Moodle admin scripts.

## What this repository provides
- A Docker image (`debian:bookworm`) with APT repository tooling installed.
- A Docker Compose service (`apt-repo`) with host/container shared folders for repo content, scripts, build automation, and GPG.
- Windows helper scripts to start, enter, and stop the container.

## Repository structure
- `Dockerfile` - Build image with tools such as `dpkg-dev` and `gnupg`.
- `docker-compose.yml` - Runs the `apt-repo` service and mounts:
  - `./repo` -> `/repo`
  - `./scripts` -> `/repo/scripts`
  - `./docker-script` -> `/docker-script`
  - `./gpg` -> `/root/.gnupg`
- `repo/` - Local APT repository content (packages, metadata).
- `scripts/release/` - Canonical script set used for package builds.
- `docker-script/` - Ordered Docker-side build scripts for `.deb` creation and APT metadata/signing.
- `commit.ver` - Release variables file for automated commit/tag flow.
- `commit_new.bat` - Reads `commit.ver`, commits changes, and creates release tag.
- `gpg/` - Local GPG keyring used for signing.
- `start.bat` - Builds image and starts the container.
- `login.bat` - Opens an interactive shell in the running container.
- `stop.bat` - Stops and removes the compose stack.

## Prerequisites
- Docker Desktop (or Docker Engine)
- Docker Compose v2 (`docker compose`)
- Windows (for `.bat` helper scripts)

## Install On Ubuntu (GPG-Signed APT)
Use this on a target Linux server after you publish the latest `repo/` to GitHub.
Note:
- Commands below assume a regular Ubuntu user with `sudo` (usually available by default).
- If you are already `root` (for example inside this Docker container), run the same commands without `sudo`.

One-time setup:
```bash
APT_BASE_URL="https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/repo"

curl -fsSL "$APT_BASE_URL/public.key" \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/jernejk-moodle-apt-repo.gpg >/dev/null

echo "deb [arch=all signed-by=/usr/share/keyrings/jernejk-moodle-apt-repo.gpg] $APT_BASE_URL stable main" \
  | sudo tee /etc/apt/sources.list.d/jernejk-moodle-apt-repo.list >/dev/null

sudo apt update
sudo apt install moodle-admin-scripts
```

Daily usage (simple):
```bash
sudo apt update
sudo apt install moodle-admin-scripts
sudo apt upgrade moodle-admin-scripts
```

Direct `.deb` fallback (without apt repo metadata):
```bash
curl -fL -o moodle-admin-scripts_0.17.0_all.deb \
  "https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/repo/pool/main/m/moodle-admin-scripts/moodle-admin-scripts_0.17.0_all.deb"
sudo apt install ./moodle-admin-scripts_0.17.0_all.deb
```

## Quick start (Windows)
1. Start container:
   ```bat
   start.bat
   ```
2. Enter container shell:
   ```bat
   login.bat
   ```
3. Work inside:
   - `/repo` for package/repo content
   - `/repo/scripts/release` for package source scripts
   - `/docker-script` for build pipeline scripts
4. Stop when done:
   ```bat
   stop.bat
   ```

## Equivalent Docker commands
Build image:
```powershell
docker build -t jernejk-moodle-apt-repo-builder .
```

Start service:
```powershell
docker compose up -d apt-repo
```

Open shell in running service:
```powershell
docker compose exec apt-repo bash
```

Stop service:
```powershell
docker compose down
```

## Notes
- Shared host/container folders are:
  - `repo/` <-> `/repo`
  - `scripts/` <-> `/repo/scripts`
  - `docker-script/` <-> `/docker-script`
  - `gpg/` <-> `/root/.gnupg`

## Build pipeline (current)
Inside container:
1. Copy config:
   ```bash
   cp /docker-script/00_config.env.example /docker-script/00_config.env
   ```
2. Edit `/docker-script/00_config.env` (for example `SCRIPTS_DIR=release`, `RELEASE_TAG`, `PKG_VERSION`, maintainer, key id).
3. Optional first-time GPG setup:
   ```bash
   bash /docker-script/07_gpg_setup.sh
   ```
4. Run in order:
   ```bash
   bash /docker-script/01_prepare_build_tree.sh
   bash /docker-script/02_build_deb.sh
   bash /docker-script/03_repo_add_package.sh
   bash /docker-script/04_repo_generate_metadata.sh
   bash /docker-script/05_repo_sign_metadata.sh
   bash /docker-script/06_smoke_test.sh
   ```
5. Or run all:
   ```bash
   bash /docker-script/run_all.sh
   ```

Result:
- `.deb` is built under `/repo/build`
- repository metadata is updated under `/repo/dists`
- package is copied under `/repo/pool`

Note:
- `run_all.sh` runs steps `01` to `06`.
- `07_gpg_setup.sh` is a separate helper (typically one-time).

## Release tracking
- Script/package releases are tracked by git tags (for example `v0.17.0`), not by numbered scripts folders.
- Use `commit.ver` + `commit_new.bat` to standardize release commits and tags.
- `commit_new.bat --help` shows full usage and all supported `commit.ver` fields.

## License
Copyright (c) 2026 Jernej K.  
All rights reserved. No license is granted to use, copy, modify, or distribute this software without explicit permission.
