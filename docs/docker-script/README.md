# docker-script
Run these scripts in order inside the container:

1. `cp /docker-script/00_config.env.example /docker-script/00_config.env`
2. Edit `00_config.env` (`SCRIPTS_DIR=release`, `RELEASE_TAG`, `PKG_VERSION`, etc.)
3. Optional first-time GPG setup: `bash /docker-script/07_gpg_setup.sh`
4. `bash /docker-script/01_prepare_build_tree.sh`
5. `bash /docker-script/02_build_deb.sh`
6. `bash /docker-script/03_repo_add_package.sh`
7. `bash /docker-script/04_repo_generate_metadata.sh`
8. `bash /docker-script/05_repo_sign_metadata.sh` (signs only when `GPG_KEY_ID` is set)
9. `bash /docker-script/06_smoke_test.sh`

Or run everything:

```bash
bash /docker-script/run_all.sh
```

Release versioning is tracked by git tags, not by numbered scripts folders.

Note:
- `run_all.sh` executes steps `01` to `06`.
- `07_gpg_setup.sh` is a separate helper (run once or when key changes).
