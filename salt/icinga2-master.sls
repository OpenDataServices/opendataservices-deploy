# Salt formula for installing and setting up icinga2 and icingaweb2

# This state requires some database setup. Either copy the database from an
# existing instance, or run:
# 
# psql --username=icinga_ido -d icinga_ido --host=127.0.0.1 <  /usr/share/icinga2-ido-pgsql/schema/pgsql.sql
# (prompts for password)
# /usr/share/icingaweb2/bin/icingacli setup config directory --group icingaweb2;
# /usr/share/icingaweb2/bin/icingacli setup token create;
#
# An then follow the setup at
# http://mon.default.opendataservices.uk0.bigv.io/icingaweb2/
# 
#
# New icingaweb2 users must be created via the database, see:
# https://github.com/Icinga/icingaweb2/blob/master/doc/authentication.md#-database-setup

include:
  - apache
  - php
  - icinga2-base

icinga2-master:
  pkg.installed:
    - pkgs:
      - postgresql
      - icinga2-ido-pgsql
      - mailutils
      # PHP Dependencies for icingaweb2
      - php5-ldap
      - php5-intl
      - php5-imagick
      - php5-pgsql
    - require:
      - pkg: icinga2
    - watch_in:
      - service: apache2

/etc/icinga2/zones.conf:
  file.managed:
    - source: salt://icinga/zone-master.conf
    - watch_in:
      - service: icinga2

/etc/icinga2/constants.conf:
  file.managed:
    - source: salt://icinga/constants.conf
    - watch_in:
      - service: icinga2

# These are the config files that only need changing for the master
# Those that need changing for all hosts are in icinga-base.sls
{% for confname in ['users', 'notifications'] %}
/etc/icinga2/conf.d/{{ confname }}.conf:
  file.managed:
    - source: salt://icinga/{{ confname }}.conf
    - watch_in:
      - service: icinga2
{% endfor %}

/etc/php5/apache2/php.ini:
  file.append:
    - text: date.timezone = Europe/London
    - watch_in: apache2
    - require:
      - pkg: libapache2-mod-php5

postgresql:
  service:
    - running
    - enable: True
    - reload: True

/etc/postgresql/9.3/main/postgresql.conf:
  file.uncomment:
    - regex: listen_addresses = 'localhost'
    - watch_in: postgresql

icingaweb2:
  group.present:
    - system: True
    - addusers:
      - www-data

https://github.com/Icinga/icingaweb2.git:
  git.latest:
    - rev: v2.0.0-beta3
    - target: /usr/share/icingaweb2/

/etc/icingaweb2/:
  file.recurse:
    - source: salt://icingaweb2
    - template: jinja

/etc/icingaweb2/enabledModules/monitoring:
  file.symlink:
    - target: /usr/share/icingaweb2/modules/monitoring
    - makedirs: True

rewrite:
  apache_module.enable

/etc/apache2/conf-available/icingaweb2.conf:
  file.managed:
    - source: salt://icinga/icingaweb2.conf
    - watch_in:
      service: apache2

/etc/apache2/conf-enabled/icingaweb2.conf:
  file.symlink:
    - target: /etc/apache2/conf-available/icingaweb2.conf
    - watch_in:
      service: apache2

/etc/icinga2/features-available/ido-pgsql.conf:
  file.managed:
    - source: salt://icinga/ido-pgsql.conf
    - template: jinja
    - watch_in:
      service: icinga2

/etc/icinga2/features-enabled/ido-pgsql.conf:
  file.symlink:
    - target: /etc/icinga2/features-available/ido-pgsql.conf
    - watch_in:
      service: icinga2

{% for name in ['icingaweb', 'icinga_ido'] %}
{{ name }}:
  postgres_user.present:
    - password: {{ pillar[name].postgres_password }}
  postgres_database.present:
    - owner: {{ name }}
    - require:
      - postgres_user: {{ name }}
{% endfor %}
