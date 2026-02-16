# Build and Publish Debian APT Package (tag-driven)

Goal: package scripts as a real Debian package (`.deb`), add it to this repository APT structure, sign metadata, and make it installable via `apt`.

## 0) Prerequisites
Run from the project root directory on host (the folder containing `start.bat`, `docker-compose.yml`, and `scripts/`).

Start container and login:
```bat
start.bat
login.bat
```

Inside container you work in `/repo` (mapped from host `./repo`) and scripts are in `/repo/scripts/release`.

## 1) Choose package identity
Example values used below:
- Package name: `moodle-admin-scripts`
- Version: `<PKG_VERSION>`
- Arch: `all`
- Install path: `/usr/local/share/moodle-admin-scripts`
- Symlink command path: `/usr/local/bin`

You can change these values, but keep naming consistent in all commands.

## 2) Create Debian package directory layout
Inside container:
```bash
cd /repo
mkdir -p build/moodle-admin-scripts_<PKG_VERSION>_all/DEBIAN
mkdir -p build/moodle-admin-scripts_<PKG_VERSION>_all/usr/local/share/moodle-admin-scripts
mkdir -p build/moodle-admin-scripts_<PKG_VERSION>_all/usr/local/bin
```

Copy scripts from canonical release folder:
```bash
cp /repo/scripts/release/*.sh build/moodle-admin-scripts_<PKG_VERSION>_all/usr/local/share/moodle-admin-scripts/
chmod 755 build/moodle-admin-scripts_<PKG_VERSION>_all/usr/local/share/moodle-admin-scripts/*.sh
```

Create symlinks/wrappers in `/usr/local/bin` (simple symlink approach):
```bash
cd build/moodle-admin-scripts_<PKG_VERSION>_all/usr/local/bin
for f in ../share/moodle-admin-scripts/*.sh; do
  base="$(basename "$f" .sh)"
  ln -sf "$f" "$base"
done
cd /repo
```

## 3) Create `DEBIAN/control`
Create file:
`/repo/build/moodle-admin-scripts_<PKG_VERSION>_all/DEBIAN/control`

Content:
```debcontrol
Package: moodle-admin-scripts
Version: <PKG_VERSION>
Section: admin
Priority: optional
Architecture: all
Maintainer: Jernej K <you@example.com>
Depends: bash, coreutils, tar, gzip, xz-utils, zstd, curl, ca-certificates
Description: Moodle/Apache/MySQL/PHP admin helper scripts
 Script bundle for Moodle environment administration and migration tasks.
 Includes help switches and prefixed command names.
```

Optional: if scripts require tools like `unzip`, `apache2`, `mysql-client`, add them to `Depends`.

## 4) Build `.deb`
```bash
cd /repo
dpkg-deb --build build/moodle-admin-scripts_<PKG_VERSION>_all
```

Result:
`/repo/build/moodle-admin-scripts_<PKG_VERSION>_all.deb`

Inspect package:
```bash
dpkg-deb -I /repo/build/moodle-admin-scripts_<PKG_VERSION>_all.deb
dpkg-deb -c /repo/build/moodle-admin-scripts_<PKG_VERSION>_all.deb
```

## 5) Add package to APT repo structure
Use this repo layout (already present under `/repo`):
- `pool/`
- `dists/`

Example distribution values:
- Codename: `stable`
- Component: `main`
- Arch: `all`

Copy package:
```bash
mkdir -p /repo/pool/main/m/moodle-admin-scripts
cp /repo/build/moodle-admin-scripts_<PKG_VERSION>_all.deb /repo/pool/main/m/moodle-admin-scripts/
```

Generate Packages index:
```bash
mkdir -p /repo/dists/stable/main/binary-all
dpkg-scanpackages /repo/pool /dev/null > /repo/dists/stable/main/binary-all/Packages
gzip -kf /repo/dists/stable/main/binary-all/Packages
```

## 6) Create and sign Release metadata
Create `Release`:
```bash
cd /repo/dists/stable
cat > Release <<EOF
Origin: JernejK
Label: JernejK Moodle Repo
Suite: stable
Codename: stable
Architectures: all
Components: main
Description: APT repository for Moodle admin scripts
EOF
```

Append checksums and sizes:
```bash
apt-ftparchive release . >> Release
```

Sign with your GPG key (mounted from `./gpg` to `/root/.gnupg`):
```bash
gpg --default-key "YOUR_KEY_ID_OR_EMAIL" -abs -o Release.gpg Release
gpg --default-key "YOUR_KEY_ID_OR_EMAIL" --clearsign -o InRelease Release
```

## 7) Commit and push to GitHub
On host (outside container), commit updated repo metadata and package:
```bash
git add repo/pool repo/dists
git commit -m "Add moodle-admin-scripts <PKG_VERSION> package"
git push
```

## 8) Client install from your GitHub APT repo
On Ubuntu client, add source (example URL, replace with your actual raw/static URL):
Note:
- Commands below assume a regular Ubuntu user with `sudo` (usually available by default).
- If you are already `root`, run the same commands without `sudo`.

On Ubuntu client, add source (example URL, replace with your actual raw/static URL):
Install your public key first:
```bash
curl -fsSL https://<YOUR_APT_BASE_URL>/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/jernejk-repo.gpg >/dev/null
```

Add source:
```bash
echo "deb [signed-by=/usr/share/keyrings/jernejk-repo.gpg] https://<YOUR_APT_BASE_URL> stable main" | sudo tee /etc/apt/sources.list.d/jernejk.list
```

Update and install:
```bash
sudo apt update
sudo apt install moodle-admin-scripts
```

## 9) Quick validation on client
```bash
apache_show_status --help
php_switch_version --help
moodle_setup --help
```

## Notes
- This is real Debian packaging, not zip/tar distribution.
- Package version changes must be reflected in:
  - control `Version`
  - `.deb` filename/path in `pool`
  - regenerated `Packages`, `Release`, signatures.
- If you later support multiple architectures, create `binary-amd64`, `binary-arm64`, etc.
