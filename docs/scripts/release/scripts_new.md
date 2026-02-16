# Script Naming Conventions (v4)

Format: old_name.sh  ->  new_name.sh
Rule: prefix by program/function (`os_`, `maria_`, `mysql_`, `db_`, `moodle_`, `php_`, `tar_`, `zip_`, `apache_`).

- apache_fix_for_phpfpm.sh  ->  apache_fix_for_phpfpm.sh
- apache_show_status.sh  ->  apache_show_status.sh
- backup_moodledata.sh  ->  moodle_backup_moodledata.sh
- backup_www.sh  ->  apache_backup_www.sh
- check_db.sh  ->  db_check.sh
- check_moodle_code.sh  ->  moodle_check_code.sh
- check_moodle_cron.sh  ->  moodle_check_cron.sh
- check_moodle_db.sh  ->  moodle_check_db.sh
- check_moodle_version.sh  ->  moodle_check_version.sh
- check_moodledata.sh  ->  moodle_check_data.sh
- check_mysql_versions_installed.sh  ->  mysql_check_versions_installed.sh
- check_mysql_versions_online.sh  ->  mysql_check_versions_online.sh
- check_stack.sh  ->  os_check_stack.sh
- compress_all.sh  ->  tar_compress_all.sh
- compress_here.sh  ->  tar_compress_here.sh
- configure_mysql.sh  ->  mysql_configure.sh
- decompress_all.sh  ->  tar_decompress_all.sh
- decompress_here.sh  ->  tar_decompress_here.sh
- install_mysql.sh  ->  mysql_install.sh
- list_all_crons.sh  ->  os_list_all_crons.sh
- list_php_dirs.sh  ->  php_list_dirs.sh
- list_php_versions.sh  ->  php_list_versions.sh
- list_sizes.sh  ->  os_list_sizes.sh
- moodle_detect.sh  ->  moodle_detect.sh
- moodle_migration_pack.sh  ->  moodle_migration_pack.sh
- moodle_migration_restore.sh  ->  moodle_migration_restore.sh
- php_install_versions.sh  ->  php_install_versions.sh
- php_switch_version.sh  ->  php_switch_version.sh
- restrict_apache.sh  ->  apache_restrict_access.sh
- setup_moodle.sh  ->  moodle_setup.sh
- setup_moodle_db.sh  ->  mysql_setup_moodle_db.sh
- uninstall_mysql.sh  ->  mysql_uninstall.sh
- update_mysql_apt.sh  ->  mysql_update_apt.sh
