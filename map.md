# map.md

This file maps the full repository workflow and all tracked files.

## 1) End-to-End Release Workflow
```mermaid
flowchart TD
  U[Run deploy.bat] --> C[Read commit.ver]
  C --> V{Config valid and scripts/release exists?}
  V -- No --> E1[Stop with error]
  V -- Yes --> D1[docker build image]
  D1 --> D2[docker compose up -d apt-repo]
  D2 --> W1[Write docker-script/00_config.env from example]
  W1 --> R1[Run docker-script/run_all.sh in container]
  R1 --> S1[01_prepare_build_tree.sh]
  S1 --> S2[02_build_deb.sh]
  S2 --> S3[03_repo_add_package.sh]
  S3 --> S4[04_repo_generate_metadata.sh]
  S4 --> S5[05_repo_sign_metadata.sh]
  S5 --> K{GPG_KEY_ID present?}
  K -- No --> K0[Skip signing]
  K -- Yes --> K1[Create InRelease and Release.gpg]
  K0 --> S6[06_smoke_test.sh]
  K1 --> S6[06_smoke_test.sh]
  S6 --> G1[Run commit_new.bat]
  G1 --> G2[git add -A]
  G2 --> G3{Any staged changes?}
  G3 -- No --> E2[Stop no changes to commit]
  G3 -- Yes --> G4[git commit]
  G4 --> G5[git tag]
  G5 --> P{PUSH true?}
  P -- No --> Z1[Release done locally]
  P -- Yes --> G6[git push branch and tag]
  G6 --> Z2[Release done remotely]
```

## 2) Script/Data Read-Write Flow
```mermaid
flowchart LR
  A1[commit.ver] --> A2[deploy.bat]
  A1 --> A3[commit_new.bat]
  A4[docker-script/00_config.env.example] --> A2
  A2 --> A5[docker-script/00_config.env]
  A2 --> A6[docker-script/run_all.sh]
  A6 --> B1[docker-script/01_prepare_build_tree.sh]
  A6 --> B2[docker-script/02_build_deb.sh]
  A6 --> B3[docker-script/03_repo_add_package.sh]
  A6 --> B4[docker-script/04_repo_generate_metadata.sh]
  A6 --> B5[docker-script/05_repo_sign_metadata.sh]
  A6 --> B6[docker-script/06_smoke_test.sh]
  C1[scripts/release/*.sh] --> B1
  B1 --> C2[repo/build/.../usr/local/share/*.sh]
  B1 --> C3[repo/build/.../usr/local/bin/* symlinks]
  B1 --> C4[repo/build/.../DEBIAN/control]
  B2 --> D1[repo/build/*.deb]
  D1 --> B3
  B3 --> D2[repo/pool/main/.../*.deb]
  B3 --> D3[repo/dists/stable/main/binary-all/Packages(.gz)]
  B4 --> D4[repo/dists/stable/Release]
  A5 --> B5
  B5 --> D5[repo/dists/stable/InRelease and Release.gpg]
  A3 --> A4
  A3 --> E1[git commit and tag]
```

## 3) Full Repository Tree (All tracked files)
```mermaid
flowchart TD
  R["jernejk-moodle-apt-repo/"]
  D1["docker-script/"]
  D2["repo/"]
  D3["scripts/"]
  D4["repo/build/"]
  D5["repo/dists/"]
  D6["repo/pool/"]
  D7["scripts/release/"]
  D8["repo/build/moodle-admin-scripts_0.17.0_all/"]
  D9["repo/dists/stable/"]
  D10["repo/pool/main/"]
  D11["repo/build/moodle-admin-scripts_0.17.0_all/DEBIAN/"]
  D12["repo/build/moodle-admin-scripts_0.17.0_all/usr/"]
  D13["repo/dists/stable/main/"]
  D14["repo/pool/main/m/"]
  D15["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/"]
  D16["repo/dists/stable/main/binary-all/"]
  D17["repo/pool/main/m/moodle-admin-scripts/"]
  D18["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/"]
  D19["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/"]
  D20["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/"]
  F1[".dockerignore"]
  F2[".gitignore"]
  F3["ClickDeploy.md"]
  F4["Dockerfile"]
  F5["Installation.md"]
  F6["README.md"]
  F7["commit.ver"]
  F8["commit_new.bat"]
  F9["deploy.bat"]
  F10["docker-compose.yml"]
  F11["docker-script/.gitkeep"]
  F12["docker-script/00_config.env.example"]
  F13["docker-script/01_prepare_build_tree.sh"]
  F14["docker-script/02_build_deb.sh"]
  F15["docker-script/03_repo_add_package.sh"]
  F16["docker-script/04_repo_generate_metadata.sh"]
  F17["docker-script/05_repo_sign_metadata.sh"]
  F18["docker-script/06_smoke_test.sh"]
  F19["docker-script/07_gpg_setup.sh"]
  F20["docker-script/README.md"]
  F21["docker-script/run_all.sh"]
  F22["gpg.md"]
  F23["login.bat"]
  F24["repo/build/moodle-admin-scripts_0.17.0_all.deb"]
  F25["repo/build/moodle-admin-scripts_0.17.0_all/DEBIAN/control"]
  F26["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/apache_backup_www"]
  F27["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/apache_fix_for_phpfpm"]
  F28["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/apache_restrict_access"]
  F29["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/apache_show_status"]
  F30["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/db_check"]
  F31["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_backup_moodledata"]
  F32["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_check_code"]
  F33["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_check_cron"]
  F34["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_check_data"]
  F35["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_check_db"]
  F36["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_check_version"]
  F37["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_detect"]
  F38["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_migration_pack"]
  F39["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_migration_restore"]
  F40["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/moodle_setup"]
  F41["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_check_versions_installed"]
  F42["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_check_versions_online"]
  F43["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_configure"]
  F44["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_install"]
  F45["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_setup_moodle_db"]
  F46["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_uninstall"]
  F47["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/mysql_update_apt"]
  F48["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/os_check_stack"]
  F49["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/os_list_all_crons"]
  F50["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/os_list_sizes"]
  F51["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/php_install_versions"]
  F52["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/php_list_dirs"]
  F53["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/php_list_versions"]
  F54["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/php_switch_version"]
  F55["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/tar_compress_all"]
  F56["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/tar_compress_here"]
  F57["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/tar_decompress_all"]
  F58["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/bin/tar_decompress_here"]
  F59["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/apache_backup_www.sh"]
  F60["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/apache_fix_for_phpfpm.sh"]
  F61["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/apache_restrict_access.sh"]
  F62["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/apache_show_status.sh"]
  F63["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/db_check.sh"]
  F64["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_backup_moodledata.sh"]
  F65["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_check_code.sh"]
  F66["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_check_cron.sh"]
  F67["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_check_data.sh"]
  F68["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_check_db.sh"]
  F69["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_check_version.sh"]
  F70["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_detect.sh"]
  F71["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_migration_pack.sh"]
  F72["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_migration_restore.sh"]
  F73["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/moodle_setup.sh"]
  F74["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_check_versions_installed.sh"]
  F75["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_check_versions_online.sh"]
  F76["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_configure.sh"]
  F77["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_install.sh"]
  F78["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_setup_moodle_db.sh"]
  F79["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_uninstall.sh"]
  F80["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/mysql_update_apt.sh"]
  F81["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/os_check_stack.sh"]
  F82["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/os_list_all_crons.sh"]
  F83["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/os_list_sizes.sh"]
  F84["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/php_install_versions.sh"]
  F85["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/php_list_dirs.sh"]
  F86["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/php_list_versions.sh"]
  F87["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/php_switch_version.sh"]
  F88["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/tar_compress_all.sh"]
  F89["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/tar_compress_here.sh"]
  F90["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/tar_decompress_all.sh"]
  F91["repo/build/moodle-admin-scripts_0.17.0_all/usr/local/share/moodle-admin-scripts/tar_decompress_here.sh"]
  F92["repo/dists/stable/Release"]
  F93["repo/dists/stable/main/binary-all/Packages"]
  F94["repo/dists/stable/main/binary-all/Packages.gz"]
  F95["repo/pool/main/m/moodle-admin-scripts/moodle-admin-scripts_0.17.0_all.deb"]
  F96["scripts/.gitkeep"]
  F97["scripts/release/apache_backup_www.sh"]
  F98["scripts/release/apache_fix_for_phpfpm.sh"]
  F99["scripts/release/apache_restrict_access.sh"]
  F100["scripts/release/apache_show_status.sh"]
  F101["scripts/release/build.md"]
  F102["scripts/release/db_check.sh"]
  F103["scripts/release/moodle_backup_moodledata.env.example"]
  F104["scripts/release/moodle_backup_moodledata.sh"]
  F105["scripts/release/moodle_check_code.env.example"]
  F106["scripts/release/moodle_check_code.sh"]
  F107["scripts/release/moodle_check_cron.sh"]
  F108["scripts/release/moodle_check_data.env.example"]
  F109["scripts/release/moodle_check_data.sh"]
  F110["scripts/release/moodle_check_db.env.example"]
  F111["scripts/release/moodle_check_db.sh"]
  F112["scripts/release/moodle_check_version.env.example"]
  F113["scripts/release/moodle_check_version.sh"]
  F114["scripts/release/moodle_detect.sh"]
  F115["scripts/release/moodle_migration_pack.sh"]
  F116["scripts/release/moodle_migration_restore.sh"]
  F117["scripts/release/moodle_setup.sh"]
  F118["scripts/release/mysql_check_versions_installed.sh"]
  F119["scripts/release/mysql_check_versions_online.sh"]
  F120["scripts/release/mysql_configure.sh"]
  F121["scripts/release/mysql_install.sh"]
  F122["scripts/release/mysql_setup_moodle_db.env.example"]
  F123["scripts/release/mysql_setup_moodle_db.sh"]
  F124["scripts/release/mysql_uninstall.sh"]
  F125["scripts/release/mysql_update_apt.sh"]
  F126["scripts/release/os_check_stack.sh"]
  F127["scripts/release/os_list_all_crons.sh"]
  F128["scripts/release/os_list_sizes.sh"]
  F129["scripts/release/php_install_versions.sh"]
  F130["scripts/release/php_list_dirs.sh"]
  F131["scripts/release/php_list_versions.sh"]
  F132["scripts/release/php_switch_version.sh"]
  F133["scripts/release/scripts.md"]
  F134["scripts/release/scripts_new.md"]
  F135["scripts/release/tar_compress_all.sh"]
  F136["scripts/release/tar_compress_here.sh"]
  F137["scripts/release/tar_decompress_all.sh"]
  F138["scripts/release/tar_decompress_here.sh"]
  F139["start.bat"]
  F140["steps.md"]
  F141["stop.bat"]
  R --> D1
  R --> D2
  R --> D3
  D2 --> D4
  D2 --> D5
  D2 --> D6
  D3 --> D7
  D4 --> D8
  D5 --> D9
  D6 --> D10
  D8 --> D11
  D8 --> D12
  D9 --> D13
  D10 --> D14
  D12 --> D15
  D13 --> D16
  D14 --> D17
  D15 --> D18
  D15 --> D19
  D19 --> D20
  R --> F1
  R --> F2
  R --> F3
  R --> F4
  R --> F5
  R --> F6
  R --> F7
  R --> F8
  R --> F9
  R --> F10
  D1 --> F11
  D1 --> F12
  D1 --> F13
  D1 --> F14
  D1 --> F15
  D1 --> F16
  D1 --> F17
  D1 --> F18
  D1 --> F19
  D1 --> F20
  D1 --> F21
  R --> F22
  R --> F23
  D4 --> F24
  D11 --> F25
  D18 --> F26
  D18 --> F27
  D18 --> F28
  D18 --> F29
  D18 --> F30
  D18 --> F31
  D18 --> F32
  D18 --> F33
  D18 --> F34
  D18 --> F35
  D18 --> F36
  D18 --> F37
  D18 --> F38
  D18 --> F39
  D18 --> F40
  D18 --> F41
  D18 --> F42
  D18 --> F43
  D18 --> F44
  D18 --> F45
  D18 --> F46
  D18 --> F47
  D18 --> F48
  D18 --> F49
  D18 --> F50
  D18 --> F51
  D18 --> F52
  D18 --> F53
  D18 --> F54
  D18 --> F55
  D18 --> F56
  D18 --> F57
  D18 --> F58
  D20 --> F59
  D20 --> F60
  D20 --> F61
  D20 --> F62
  D20 --> F63
  D20 --> F64
  D20 --> F65
  D20 --> F66
  D20 --> F67
  D20 --> F68
  D20 --> F69
  D20 --> F70
  D20 --> F71
  D20 --> F72
  D20 --> F73
  D20 --> F74
  D20 --> F75
  D20 --> F76
  D20 --> F77
  D20 --> F78
  D20 --> F79
  D20 --> F80
  D20 --> F81
  D20 --> F82
  D20 --> F83
  D20 --> F84
  D20 --> F85
  D20 --> F86
  D20 --> F87
  D20 --> F88
  D20 --> F89
  D20 --> F90
  D20 --> F91
  D9 --> F92
  D16 --> F93
  D16 --> F94
  D17 --> F95
  D3 --> F96
  D7 --> F97
  D7 --> F98
  D7 --> F99
  D7 --> F100
  D7 --> F101
  D7 --> F102
  D7 --> F103
  D7 --> F104
  D7 --> F105
  D7 --> F106
  D7 --> F107
  D7 --> F108
  D7 --> F109
  D7 --> F110
  D7 --> F111
  D7 --> F112
  D7 --> F113
  D7 --> F114
  D7 --> F115
  D7 --> F116
  D7 --> F117
  D7 --> F118
  D7 --> F119
  D7 --> F120
  D7 --> F121
  D7 --> F122
  D7 --> F123
  D7 --> F124
  D7 --> F125
  D7 --> F126
  D7 --> F127
  D7 --> F128
  D7 --> F129
  D7 --> F130
  D7 --> F131
  D7 --> F132
  D7 --> F133
  D7 --> F134
  D7 --> F135
  D7 --> F136
  D7 --> F137
  D7 --> F138
  R --> F139
  R --> F140
  R --> F141
```

## 4) Suggested Additional Visuals
- A lane diagram with 4 lanes: Windows Host, Docker Container, Repo Files, GitHub Remote.
- A state diagram for release lifecycle: Draft -> Built -> Indexed -> Signed -> Tested -> Committed -> Tagged -> Pushed.
- A dependency heatmap (table) mapping each packaged script to required binaries (bash, mysql, php, apachectl, tar, etc.).
- A Graphviz/PNG export pipeline so every commit can regenerate visuals automatically.
