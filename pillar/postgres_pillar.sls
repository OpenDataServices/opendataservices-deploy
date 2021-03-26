# -*- coding: utf-8 -*-
# vim: ft=yaml
---
# Port to use for the cluster -- can be used to provide a non-standard port
# NOTE: If already set in the minion config, that value takes priority

postgres:
  use_upstream_repo: true
  version: '13'
  add_profile: false
  cluster:
    locale: en_GB.UTF-8



  # Path to the `pg_hba.conf` file Jinja template on Salt Fileserver
  pg_hba.conf: salt://postgres/templates/pg_hba.conf.j2

  config_backup: False
  acls:
   - ['local', 'all', 'postgres', 'peer']
   - ['local', 'all', 'all', 'md5']
   - ['host', 'all', 'all', '0.0.0.0/0', 'md5']



  # Default acl
  #local   all             postgres                                peer

  # TYPE  DATABASE        USER            ADDRESS                 METHOD

  #local   all             all                                     peer
  #host    all             all             127.0.0.1/32            md5
  #host    all             all             ::1/128                 md5

  #local   replication     all                                     peer
  #host    replication     all             127.0.0.1/32            md5
  #host    replication     all             ::1/128                 md5
