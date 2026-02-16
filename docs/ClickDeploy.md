# Click Deploy

One command release flow:

```bat
deploy.bat
```

## What `deploy.bat` does (in order)
1. Reads `commit.ver`.
2. Validates required values (`RELEASE_TAG`, `PKG_VERSION`, `SCRIPTS_DIR`, etc.).
3. Verifies Docker daemon is running.
4. Builds image and starts container (`apt-repo`).
5. Creates/updates `docker-script/00_config.env` from `commit.ver` values.
6. Runs Docker build pipeline inside container:
   - `bash /docker-script/run_all.sh`
7. Runs release commit/tag flow:
   - `commit_new.bat`

## Required file
- `commit.ver`

## Minimal `commit.ver` fields
- `RELEASE_TAG=vX.Y.Z`
- `PKG_VERSION=X.Y.Z`
- `SCRIPTS_DIR=release`
- `COMMIT_MESSAGE=Release moodle-admin-scripts vX.Y.Z`
- `TAG_MESSAGE=Release vX.Y.Z`
- `PUSH=true` (or `false`)
- `REMOTE=origin`
- `BRANCH=main`

Optional:
- `GPG_KEY_ID=<key-id-or-email>`
- `MAINTAINER_NAME=Your Name`
- `MAINTAINER_EMAIL=you@example.com`

## Help
```bat
deploy.bat --help
```
