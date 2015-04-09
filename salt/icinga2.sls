# Salt formula for installing and setting up icinga2 and icingaweb2

# TODO:
# Currently in addition to running this state these commands need to be run
# manually, and then the setup at
# http://mon.default.opendataservices.uk0.bigv.io/icingaweb2/ needs to be
# followed.
#
# psql --username=icinga_ido -d icinga_ido --host=127.0.0.1 <  /usr/share/icinga2-ido-pgsql/schema/pgsql.sql
# (prompts for password)
# /usr/share/icingaweb2/bin/icingacli setup config directory --group icingaweb2;
# /usr/share/icingaweb2/bin/icingacli setup token create;

include:
  - apache

icinga2:
  pkgrepo.managed:
    - ppa: formorer/icinga
    - require_in:
      pkg: icinga2
  pkg.installed:
    - pkgs:
      - icinga2
      - nagios-plugins
      - postgresql
      - icinga2-ido-pgsql
      # PHP Dependencies for icingaweb2
      - php5-ldap
      - php5-intl
      - php5-imagick
    - refresh: True
  service:
    - running
    - enable: True
    - reload: True

/etc/php5/apache2/php.ini:
  file.append:
    - text: date.timezone = Europe/London
    - watch_in: apache2

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

./bin/icingacli setup config webserver apache --document-root /usr/share/icingaweb2/public > /etc/apache2/conf-available/icingaweb2.conf:
  cmd.run:
    - cwd: /usr/share/icingaweb2
    - onchanges:
      - git: https://github.com/Icinga/icingaweb2.git
    - watch_in: apache2

/etc/apache2/conf-enabled/icingaweb2.conf:
  file.symlink:
    - target: /etc/apache2/conf-available/icingaweb2.conf
    - watch_in: apache2

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
