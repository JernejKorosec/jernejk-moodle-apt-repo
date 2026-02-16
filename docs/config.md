# Configuration Reference

This file lists user-set values, config files, and generated files for a fresh end-to-end flow:
- build/sign/publish the APT repo
- install package on Ubuntu
- run packaged scripts that need user input

## 1) Config Files To Create/Edit

| File | Required | Purpose | How to create |
| --- | --- | --- | --- |
| `commit.ver` | Yes | Release metadata for `deploy.bat` and `commit_new.bat`. | Edit existing file in repo root. |
| `docker/docker-script/00_config.env` | Yes | Main Docker build/repo-sign config. | `cp docker/docker-script/00_config.env.example docker/docker-script/00_config.env` (or run `deploy.bat`, which writes it). |
| `scripts/release/moodle_backup_moodledata.env` | Optional | Persist `DATA_DIR` for backup script. | Copy from `.env.example`. |
| `scripts/release/moodle_check_code.env` | Optional | Persist `MOODLE_CODE_DIR` for code check script. | Copy from `.env.example`. |
| `scripts/release/moodle_check_data.env` | Optional | Persist `CONFIG_FILE` for data check script. | Copy from `.env.example`. |
| `scripts/release/moodle_check_db.env` | Optional | Persist `CONFIG_FILE` for DB check script. | Copy from `.env.example`. |
| `scripts/release/moodle_check_version.env` | Optional | Persist `MOODLE_PATH` for version check script. | Copy from `.env.example`. |
| `scripts/release/mysql_setup_moodle_db.env` | Optional | Persist Moodle DB credentials for DB setup script. | Copy from `.env.example`. |
| `scripts/release/mysql_root.txt` | Optional | Root password file used by `mysql_setup_moodle_db.sh` via `ROOT_PASS_FILE`. | Create manually if you do not want prompt input. |

## 2) Variables By File

### `commit.ver`

| Variable | Required | Example | Notes |
| --- | --- | --- | --- |
| `RELEASE_TAG` | Yes | `v0.18.0` | Git tag name. |
| `PKG_VERSION` | Recommended | `0.18.0` | If missing, derived from tag without `v`. |
| `SCRIPTS_DIR` | No | `release` | Folder under `scripts/`. |
| `COMMIT_MESSAGE` | No | `Release moodle-admin-scripts v0.18.0` | Commit message text. |
| `TAG_MESSAGE` | No | `Release v0.18.0` | Annotated tag message. |
| `PUSH` | No | `false` | `true/false`, `yes/no`, `1/0`. |
| `REMOTE` | No | `origin` | Git remote for push. |
| `BRANCH` | No | `main` | Branch for push. |
| `GPG_KEY_ID` | Optional | `ABCD1234EF...` | Used by `deploy.bat` to populate `00_config.env`. |
| `MAINTAINER_NAME` | Optional | `Jane Doe` | Used by `deploy.bat` to populate `00_config.env`. |
| `MAINTAINER_EMAIL` | Optional | `jane@example.com` | Used by `deploy.bat` to populate `00_config.env`. |

### `docker/docker-script/00_config.env`

| Variable | Required | Example |
| --- | --- | --- |
| `REPO_ROOT` | Yes | `/repo` |
| `SCRIPTS_DIR` | Yes | `release` |
| `RELEASE_TAG` | Yes | `v0.18.0` |
| `PKG_NAME` | Yes | `moodle-admin-scripts` |
| `PKG_VERSION` | Yes | `0.18.0` |
| `PKG_ARCH` | Yes | `all` |
| `MAINTAINER_NAME` | Yes | `Jane Doe` |
| `MAINTAINER_EMAIL` | Yes | `jane@example.com` |
| `PKG_SECTION` | Yes | `admin` |
| `PKG_PRIORITY` | Yes | `optional` |
| `PKG_DEPENDS` | Yes | `bash,coreutils,tar,gzip,xz-utils,zstd,curl,ca-certificates` |
| `DIST_CODENAME` | Yes | `stable` |
| `DIST_COMPONENT` | Yes | `main` |
| `GPG_KEY_ID` | Optional | `ABCD1234EF...` |

Note: if `GPG_KEY_ID` is empty, signing step `05_repo_sign_metadata.sh` is skipped.

### Script-local env files in `scripts/release/`

| File | Variables | Example values |
| --- | --- | --- |
| `moodle_backup_moodledata.env` | `DATA_DIR` | `DATA_DIR="/var/opt/moodledata"` |
| `moodle_check_code.env` | `MOODLE_CODE_DIR` | `MOODLE_CODE_DIR="/var/www/moodle"` |
| `moodle_check_data.env` | `CONFIG_FILE` | `CONFIG_FILE="/var/www/moodle/config.php"` |
| `moodle_check_db.env` | `CONFIG_FILE` | `CONFIG_FILE="/var/www/moodle/config.php"` |
| `moodle_check_version.env` | `MOODLE_PATH` | `MOODLE_PATH="/var/www/moodle"` |
| `mysql_setup_moodle_db.env` | `DB_NAME`, `DB_USER`, `DB_PASS`, `MYSQL_ROOT_PASS`, `ROOT_PASS_FILE` | `DB_NAME="moodle"`, `DB_USER="moodleuser"`, `DB_PASS="strong-pass"`, `MYSQL_ROOT_PASS="root-pass"`, `ROOT_PASS_FILE="mysql_root.txt"` |

### Ubuntu client install placeholders

| Variable | Example | Used in |
| --- | --- | --- |
| `APT_BASE_URL` | `https://raw.githubusercontent.com/<owner>/<repo>/main/repo` | Key download and apt source line. |
| `KEYRING_PATH` | `/usr/share/keyrings/jernejk-moodle-apt-repo.gpg` | `signed-by=` location. |
| `SOURCE_LIST_PATH` | `/etc/apt/sources.list.d/jernejk-moodle-apt-repo.list` | Apt source file path. |
| `DIST_CODENAME` | `stable` | Apt source line. |
| `DIST_COMPONENT` | `main` | Apt source line. |
| `PKG_NAME` | `moodle-admin-scripts` | `apt install` target. |

## 3) Runtime Input Variables (CLI Arguments/Options)

These are not persistent config files, but still require user input when running scripts.

| Script | Variable names to provide | Example |
| --- | --- | --- |
| `scripts/release/apache_restrict_access.sh` | `MY_IP`, `SITE_CONF_NAME` | `sudo apache_restrict_access.sh 203.0.113.10 moodle.conf` |
| `scripts/release/moodle_setup.sh` | `MOODLE_URL`, `MOODLE_CODE_DIR`, `MOODLE_DATA_DIR` | `sudo moodle_setup.sh https://moodle.example.com /var/www/moodle /var/moodledata` |
| `scripts/release/moodle_backup_moodledata.sh` | `DATA_DIR` | `DATA_DIR="/var/opt/moodledata"` in env file, or prompt input at runtime |
| `scripts/release/moodle_check_code.sh` | `MOODLE_CODE_DIR` | `MOODLE_CODE_DIR="/var/www/moodle"` in env file, or prompt input at runtime |
| `scripts/release/moodle_check_data.sh` | `CONFIG_FILE` | `CONFIG_FILE="/var/www/moodle/config.php"` in env file, or prompt input at runtime |
| `scripts/release/moodle_check_db.sh` | `CONFIG_FILE` | `CONFIG_FILE="/var/www/moodle/config.php"` in env file, or prompt input at runtime |
| `scripts/release/moodle_check_version.sh` | `MOODLE_PATH` | `MOODLE_PATH="/var/www/moodle"` in env file, or prompt input at runtime |
| `scripts/release/mysql_setup_moodle_db.sh` | `DB_NAME`, `DB_USER`, `DB_PASS`, `MYSQL_ROOT_PASS` | Set in `mysql_setup_moodle_db.env` or enter when prompted |
| `scripts/release/php_install_versions.sh` | `PHP_VERSION` | `sudo php_install_versions.sh 8.2` |
| `scripts/release/php_switch_version.sh` | `PHP_VERSION` | `sudo php_switch_version.sh 8.2` |
| `scripts/release/tar_compress_all.sh` | `SOURCE_DIR`, `OUTPUT_FILE` (optional), `FORMAT` (optional) | `tar_compress_all.sh --format xz /var/www moodle_www.tar.xz` |
| `scripts/release/tar_decompress_all.sh` | `ARCHIVE_FILE`, `OUTPUT_DIR` (optional) | `tar_decompress_all.sh moodle_www.tar.xz /restore` |
| `scripts/release/moodle_detect.sh` | `CONFIG_PATH` (optional), `VHOST_PATH` (optional), `OUT_PATH` (optional) | `moodle_detect.sh --config /var/www/moodle/config.php --out ./moodle_detect.env` |
| `scripts/release/moodle_migration_pack.sh` | `CONFIG_PATH` or `DIRROOT`, `DATAROOT`, `TARGET_MOODLE` (optional), `OUT_DIR` (optional) | `moodle_migration_pack.sh --config /var/www/moodle/config.php --target-moodle 4.2` |
| `scripts/release/moodle_migration_restore.sh` | `IN_DIR`, `DIRROOT`, `DATAROOT`, optional DB and URL values | `moodle_migration_restore.sh --in ./moodle_migration_20260216_120000 --dirroot /var/www/moodle --dataroot /var/moodledata --wwwroot https://moodle.example.com` |

## 4) Generated/Updated Files

| File or pattern | Created/updated by | Notes |
| --- | --- | --- |
| `docker/docker-script/00_config.env` | Manual copy or `deploy.bat` | Main runtime config for Docker scripts. |
| `docker/docker-script/00_config.env.example` | `commit_new.bat` | Updates `SCRIPTS_DIR`, `RELEASE_TAG`, `PKG_VERSION`. |
| `repo/build/<pkg>_<ver>_<arch>/DEBIAN/control` | `01_prepare_build_tree.sh` | Generated Debian control file. |
| `repo/build/<pkg>_<ver>_<arch>.deb` | `02_build_deb.sh` | Built package artifact. |
| `repo/pool/main/<first-letter>/<pkg>/<pkg>_<ver>_<arch>.deb` | `03_repo_add_package.sh` | Repo package copy. |
| `repo/dists/<codename>/<component>/binary-<arch>/Packages` and `Packages.gz` | `03_repo_add_package.sh` | Apt package index. |
| `repo/dists/<codename>/Release` | `04_repo_generate_metadata.sh` | Release metadata. |
| `repo/dists/<codename>/InRelease` and `Release.gpg` | `05_repo_sign_metadata.sh` | Only if `GPG_KEY_ID` is set. |
| `repo/public.key` | `07_gpg_setup.sh` | Exported public key for apt clients. |
| `moodle_detect.env` (default) | `moodle_detect.sh` | Generated settings file used by migration scripts. |
| `moodle_migration_YYYYMMDD_HHMMSS/` | `moodle_migration_pack.sh` | Contains `moodle_code.tar.gz`, `moodledata.tar.gz`, optional `moodle_db.sql`. |
| `config.php.bak` | `moodle_migration_restore.sh` | Backup created when config values are updated. |
| `www_backup_YYYYMMDD_HHMMSS.tar.gz` | `apache_backup_www.sh` | Backup in current working directory. |
| `moodledata_backup_YYYYMMDD_HHMMSS.tar.gz` | `moodle_backup_moodledata.sh` | Backup in current working directory. |
| `archive_YYYYMMDD_HHMMSS.tar.xz` | `tar_compress_here.sh` | Archive in current working directory. |
| `*_YYYYMMDD_HHMMSS.log` | `mysql_install.sh`, `mysql_configure.sh`, `mysql_setup_moodle_db.sh` | Timestamped logs in current directory. |
| `/etc/mysql/mysql.conf.d/mysqld.cnf.backup_YYYYMMDD_HHMMSS` | `mysql_configure.sh` | MySQL config backup. |
| `/etc/apache2/sites-available/<site-conf>.bak` | `apache_restrict_access.sh` | Apache site config backup. |

## 5) Minimal Fresh Setup Checklist

1. Set release values in `commit.ver`.
2. Create `docker/docker-script/00_config.env` from example (or run `deploy.bat`).
3. (Optional) Run `bash /docker-script/07_gpg_setup.sh` to generate/export key and set `GPG_KEY_ID`.
4. Build/sign pipeline via `bash /docker-script/run_all.sh` (or `deploy.bat` for full one-click flow).
5. If needed, create script-local `.env` files in `scripts/release/` to avoid prompts.
6. Publish/commit generated repo files (`repo/pool`, `repo/dists`, `repo/public.key` when signing).
7. On Ubuntu client, set `APT_BASE_URL`, import key, add source list, then `apt install moodle-admin-scripts`.

Security note: do not commit real secrets in `.env` files; this repo ignores `scripts/**/*.env` and `docker/docker-script/00_config.env`.
