# Installation

Install `moodle-admin-scripts` from this GitHub-hosted APT repository on Ubuntu.

## 1) Add repository
```bash
echo "deb [trusted=yes] https://raw.githubusercontent.com/JernejKorosec/jernejk-moodle-apt-repo/main/repo stable main" | sudo tee /etc/apt/sources.list.d/jernejk.list
```

## 2) Update package lists
```bash
sudo apt update
```

## 3) Install package
```bash
sudo apt install moodle-admin-scripts
```

## 4) Quick verification
```bash
apache_show_status --help
php_switch_version --help
moodle_setup --help
```

## Notes
- This setup uses `trusted=yes` (unsigned repo mode).
- For production use, prefer signed repository metadata with a GPG key.
- GPG helper inside container: `bash /docker-script/07_gpg_setup.sh`
