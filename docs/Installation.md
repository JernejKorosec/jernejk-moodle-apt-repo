# Installation

Install `moodle-admin-scripts` from this GitHub-hosted APT repository on Ubuntu (GPG-signed mode).
Note:
- Commands below assume a regular Ubuntu user with `sudo` (usually available by default).
- If you are already `root` (for example inside Docker), run the same commands without `sudo`.

## 1) Import repository public key
```bash
APT_BASE_URL="https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/repo"
curl -fsSL "$APT_BASE_URL/public.key" | gpg --dearmor | sudo tee /usr/share/keyrings/jernejk-moodle-apt-repo.gpg >/dev/null
```

## 2) Add repository
```bash
echo "deb [arch=all signed-by=/usr/share/keyrings/jernejk-moodle-apt-repo.gpg] $APT_BASE_URL stable main" | sudo tee /etc/apt/sources.list.d/jernejk-moodle-apt-repo.list >/dev/null
```

## 3) Update package lists
```bash
sudo apt update
```

## 4) Install package
```bash
sudo apt install moodle-admin-scripts
```

## 5) Update package later
```bash
sudo apt update
sudo apt install --only-upgrade moodle-admin-scripts
```

## 6) Optional helper scripts
```bash
BASE_URL="https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/linux-client"
curl -fLO "$BASE_URL/install_repo_and_package.sh"
curl -fLO "$BASE_URL/update_package.sh"
curl -fLO "$BASE_URL/uninstall_package_and_repo.sh"
chmod +x install_repo_and_package.sh update_package.sh uninstall_package_and_repo.sh
```

## 7) Quick verification
```bash
apache_show_status --help
php_switch_version --help
moodle_setup --help
```

## Optional direct `.deb` install
```bash
curl -fL -o moodle-admin-scripts_0.17.1_all.deb \
  "https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/repo/pool/main/m/moodle-admin-scripts/moodle-admin-scripts_0.17.1_all.deb"
sudo apt install ./moodle-admin-scripts_0.17.1_all.deb
```
