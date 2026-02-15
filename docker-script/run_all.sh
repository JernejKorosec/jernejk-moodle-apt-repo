#!/usr/bin/env bash
set -euo pipefail

bash /docker-script/01_prepare_build_tree.sh
bash /docker-script/02_build_deb.sh
bash /docker-script/03_repo_add_package.sh
bash /docker-script/04_repo_generate_metadata.sh
bash /docker-script/05_repo_sign_metadata.sh
bash /docker-script/06_smoke_test.sh

echo "All steps completed."
