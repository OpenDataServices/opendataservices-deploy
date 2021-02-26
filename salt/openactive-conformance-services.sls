
# Open active conformance services running on dokku with a local database

install_db_server:
  pkg.installed:
    - pkgs:
      - postgresql-12
      - postgresql-client-12

postgresql:
  service:
    - running
    - enable: True
    - reload: True

/etc/postgresql/12/main/pg_hba.conf:
  file.append:
    - text:
       - "host 	{{pillar.postgresql_db_name}} 	{{pillar.postgresql_user}} 	172.17.0.1/12 	md5"

/etc/postgresql/12/main/postgresql.conf:
  file.append:
    - text:
      - "listen_addresses = 'localhost, {{pillar.postgresql_host}}'"


database_setup:

  postgres_user.present:
    - name: {{ pillar.postgresql_user }}
    - password: {{ pillar.postgresql_password}}
    - require:
      - service: postgresql


  postgres_database.present:
    - name: {{pillar.postgresql_db_name }}
    - owner: {{ pillar.postgresql_user }}
    - require:
      - service: postgresql
      - postgres_user: {{ pillar.postgresql_user }}


create_app:
  cmd.run:
    - name: |
        dokku apps:create conformance-services || true
        dokku config:set conformance-services DATABASE_URL=postgres://{{pillar.postgresql_user}}:{{pillar.postgresql_password}}@{{pillar.postgresql_host}}/{{pillar.postgresql_db_name}} WORKER_SLEEP=1 --no-restart

    - runas: root


### Setup our special logging

/var/log/conformance-services:
  file.directory:
    - user: root
    - group: root
    - mkdirs: True

/etc/logrotate.d/conformance-services.conf:
  file.append:
    - text:
      - "/var/log/conformance-services/*.log {"
      - "             daily"
      - "             rotate 14"
      - "             compress"
      - "             missingok"
      - "             notifempty"
      - "}"


# not using logrotate.set state due to https://github.com/saltstack/salt/issues/48125

## Setup scheduled jobs
# Run as root but actually via dokku

spider-cron:
  cron.present:
    - name: 'dokku run conformance-services "node ./src/bin/spider-data-catalog.js" >> /var/log/conformance-services/spider.log 2>&1'
    - user: root
    - minute: '*/30'

stats-cron:
  cron.present:
    - name: 'dokku run conformance-services "node ./src/bin/update-publisher-feed-stats.js" >> /var/log/conformance-services/update-stats.log 2>&1'
    - user: root
    - minute: '*/30'

clean-up-cron:
  cron.present:
    - name: 'dokku run conformance-services "node ./src/bin/clean-up-database.js" >> /var/log/conformance-services/clean-up-database.log 2>&1'
    - user: root
    - minute: '*/30'



