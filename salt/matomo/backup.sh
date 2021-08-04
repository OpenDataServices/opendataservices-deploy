#!/bin/bash

set -e

mysqldump --no-tablespaces --extended-insert --no-autocommit --quick --single-transaction piwik -upiwik --result-file=/home/{{user}}/backups/matomo_backup_database-new.sql

mv /home/{{user}}/backups/matomo_backup_database-new.sql /home/{{user}}/backups/matomo_backup_database.sql
