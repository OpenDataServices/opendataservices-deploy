#!/bin/bash

pg_dump pwyf_tracker > ~/backups/backup_$(date +"%F").sql

sqlite3 /home/pwyf_tracker/pwyf_tracker/sample_work.db ".backup '/home/pwyf_tracker/backups/sample_work_backup_$(date +"%F").db'"

X_AUTH_TOKEN=$(curl -I -H "x-auth-user: {{ pillar.pwyf_tracker.brightbox_backup.user }}" -H "x-auth-key: {{ pillar.pwyf_tracker.brightbox_backup.key }}" https://orbit.brightbox.com/v1/acc-7ufuy/pwyf-tracker-backups | grep X-Auth-Token | awk '{ print $2 }' | tr '\r' ' ')
for f in ~/backups/*$(date +"%F")*; do
    curl -I -T $f -X PUT -H "x-auth-token: $X_AUTH_TOKEN" https://orbit.brightbox.com/v1/acc-7ufuy/pwyf-tracker-backups/{{ pillar.pwyf_tracker.brightbox_backup.subdir }}/$(basename $f)
done
