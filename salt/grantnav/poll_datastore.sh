#!/bin/bash
DATE=`date +%F`
python3 /home/{{ user }}/poll_datastore.py --url {{ datastore_url}} --username={{ datastore_user }} --password={{ datastore_password }} --load-grantnav-script /home/{{ user }}/reload_latest_daily.sh >> /home/{{ user }}/logs/cron_$DATE.log 2>&1
