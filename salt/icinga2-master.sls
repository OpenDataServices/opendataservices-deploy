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
# As of icingaweb2.0-rc1, New users can be added through the web interface.


include:
  - apache
  - php
  - icinga2-base


# YaY for the bloody idiot who churned up all the php package names between
# 14.04 and 16.04.  This is bad enough ...
{% if grains['lsb_distrib_release']=='14.04' %}
  {% set phpver='5' %}
{% else %}
  {% set phpver='7.0' %}
{% endif %}
# ... but as you will see, there are special cases ...

# ... and here's your first special case.
{% if grains['lsb_distrib_release']=='14.04' %}
php-imagick:
  pkg.installed:
    - name: php5-imagick
{% else %}
php-imagick:
  pkg.installed
{% endif %}

icinga2-master:
  pkg.installed:
    - pkgs:
      - postgresql
      - icinga2-ido-pgsql
      - mailutils
      # PHP Dependencies for icingaweb2
      - php{{ phpver }}-ldap
      - php{{ phpver }}-intl
      - php{{ phpver }}-pgsql
    - require:
      - pkg: icinga2
      - pkg: php-imagick
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
    - template: jinja
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



{% if grains['lsb_distrib_release']=='14.04' %}

/etc/php5/apache2/php.ini:
  file.append:
    - text: date.timezone = Europe/London
    - watch_in: apache2
    - require:
      - pkg: libapache2-mod-php{{ phpver }}

{% else %}

/etc/php/7.0/apache2/php.ini:
  file.append:
    - text: date.timezone = Europe/London
    - watch_in: apache2
    - require:
      - pkg: libapache2-mod-php{{ phpver }}

{% endif %}


postgresql:
  service:
    - running
    - enable: True
    - reload: True

{% if grains['lsb_distrib_release']=='14.04' %}
  {% set pgver='9.3' %}
{% else %}
  {% set pgver='9.5' %}
{% endif %}

/etc/postgresql/{{ pgver }}/main/postgresql.conf:
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
    - rev: v2.4.0
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

{% for feature in ['ido-pgsql', 'command'] %}
/etc/icinga2/features-enabled/{{ feature }}.conf:
  file.symlink:
    - target: /etc/icinga2/features-available/{{ feature }}.conf
    - watch_in:
      - service: icinga2
{% endfor %}

{% for name in ['icingaweb', 'icinga_ido'] %}
{{ name }}:
  postgres_user.present:
    - password: {{ pillar[name].postgres_password }}
  postgres_database.present:
    - owner: {{ name }}
    - require:
      - postgres_user: {{ name }}
{% endfor %}
