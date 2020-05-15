# Salt formula for installing matomo f/k/a piwik
#
# For two purposes we're retaining the name 'piwik' for now:
#   (1) all urls in the pillars, and the corresponding server directory /var/www/html/piwik/
#   (2) the mysql database name and username

include:
  - apache
  - php


# Download matomo from the git repository but pick a tag for a stable release
https://github.com/matomo-org/matomo.git:
  git.latest:
    - rev: 3.13.5
    - target: /var/www/html/piwik/
    - submodules: True
# Upstream matomo routinely rewrites history in their git repo, so we'll set
# this permanently
    - force_fetch: True


# matomo's PHP deps:

{% if grains['lsb_distrib_release']=='14.04' %}
  {% set phpver='5' %}
{% elif grains['lsb_distrib_release']=='16.04' %}
  {% set phpver='7.0' %}
{% elif grains['lsb_distrib_release']=='18.04' %}
  {% set phpver='7.2' %}
{% elif grains['lsb_distrib_release']=='20.04' %}
  {% set phpver='7.4' %}
{% else %}
  {% set phpver='wtf' %}
{% endif %}

php{{ phpver }}-cli:
  pkg.installed

php{{ phpver }}-curl:
  pkg.installed

php{{ phpver }}-gd:
  pkg.installed:
    - watch_in:
      - service: apache2

php-mbstring:
  pkg.installed

php{{ phpver }}-mysql:
  pkg.installed:
    - watch_in:
      - service: apache2

geoip-deps:
  pkg.installed:
    - pkgs:
      - php-geoip
      - php{{ phpver }}-dev
      - libgeoip-dev

moar-memory:
  file.replace:
    - name: /etc/php/{{ phpver }}/apache2/php.ini
    - pattern: memory_limit = 128M
    - repl: memory_limit = 256M

moar-time:
  file.replace:
    - name: /etc/php/{{ phpver }}/apache2/php.ini
    - pattern: max_execution_time = 30
    - repl: max_execution_time = 180

# Install composer (PHP package manager), and its deps
# see http://docs.saltstack.com/en/latest/ref/states/all/salt.states.composer.html

curl:
  pkg.installed

unzip:
  pkg.installed

get-composer:
  cmd.run:
    - name: 'CURL=`which curl`; $CURL -sS https://getcomposer.org/installer | php'
    - unless: test -f /usr/local/bin/composer
    - cwd: /root/

install-composer:
  cmd.wait:
    - name: mv /root/composer.phar /usr/local/bin/composer
    - cwd: /root/
    - watch:
      - cmd: get-composer

# Run composer in matomo's root directory
/var/www/html/piwik/:
  composer.installed:
    - no_dev: true
    - require:
      - cmd: install-composer


# Other setup in matomo's root directory

/var/www/html/piwik/tmp:
  file.directory:
    - user: www-data
    - group: www-data

/var/www/html/piwik/config:
  file.directory:
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group

# (note, this file needs to be inspected and merged manually on the server,
# in case changes have been made through matomo's web admin interface)
/var/www/html/piwik/config/config.ini.php.salt:
  file.managed:
    - source: salt://matomo/config.ini.php
    - user: www-data
    - group: www-data
    - mode: 644

/var/www/html/piwik/matomo.js:
  file.managed:
    - user: www-data
    - group: www-data
    - mode: 644


# mysql installation and matomo database creation
# see https://github.com/saltstack-formulas/piwik-formula/blob/master/piwik/mysql.sls

mysql-deps:
  pkg.installed:
    - pkgs:
      - mysql-server
      - mysql-client
      - python3-mysqldb
    - require_in:
      - service: mysql
      - mysql_user: piwik

mysql:
  service.running:
    - watch:
      - pkg: mysql-deps

piwik_db_user:
  mysql_user.present:
    - name: piwik
    - host: localhost
    - password: {{ pillar.piwik.mysql_password }}
    - require:
      - pkg: mysql-deps
      - service: mysql

piwik_db:
  mysql_database.present:
    - name: piwik
    - require:
      - mysql_user: piwik
      - pkg: mysql-deps
  mysql_grants.present:
    - grant: all privileges
    - database: piwik.*
    - host: localhost
    - user: piwik
    - require:
      - mysql_database: piwik
      - pkg: mysql-deps
      - service: mysql
