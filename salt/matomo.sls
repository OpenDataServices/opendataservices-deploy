# This is for Ubuntu 20

# Salt formula for installing Matomo
#
# This state requires some database setup. Either copy the database from an
# existing instance, or use the install wizard at:
# http://mon.opendataservices.coop/piwik/

include:
  - apache
  - letsencrypt

{% from 'lib.sls' import createuser, apache %}

{% set user = 'matomo' %}
{{ createuser(user) }}


# Download Matomo from the git repository but pick a tag for a stable release
# The target is /home/{{ user }}/www/piwik/.
# It is NOT /home/{{ user }}/www/matomo/ because then we would have to change all clients to send data to /matomo and not /piwik
https://github.com/matomo-org/matomo.git:
  git.latest:
    - rev: 4.3.1
    - target: /home/{{ user }}/www/piwik/
    - submodules: True
# Upstream matomo routinely rewrites history in their git repo, so we'll set
# this permanently
    - force_fetch: True
# Other salt commands change permissions, and that shows up as git changes. So force_reset
    - force_reset: True


# Database

mysql-server:
  pkg.installed

# PHP deps

php-deps:
  pkg.installed:
    - pkgs:
      - php-curl
      - php-gd
      - php-mysql
      - php-cli
      - php-zip
      - php-xml
      - php-mbstring
      - libapache2-mod-php


# Install composer (PHP package manager),
# see http://docs.saltstack.com/en/latest/ref/states/all/salt.states.composer.html

curl:
  pkg.installed

get-composer:
  cmd.run:
    - name: 'curl -s -S https://getcomposer.org/installer | php'
    - unless: test -f /usr/local/bin/composer
    - cwd: /root/
    - require:
      - pkg: php-deps
      - pkg: curl

install-composer:
  cmd.wait:
    - name: mv /root/composer.phar /usr/local/bin/composer
    - cwd: /root/
    - watch:
      - cmd: get-composer

# Install piwik's dependencies
/home/{{ user }}/www/piwik/:
  composer.installed:
    - no_dev: true
    - require:
      - cmd: install-composer

/home/{{ user }}/www/piwik/tmp:
  file.directory:
    - user: www-data
    - group: www-data
    # Uncommented because the git state often fails for me due to
    # https://github.com/saltstack/salt/issues/22514
    #- require:
    #  - git: https://github.com/piwik/piwik.git

/home/{{ user }}/www/piwik/config:
  file.directory:
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group

# GeoIP Database is saved here
/home/{{ user }}/www/piwik/misc:
  file.directory:
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group


{{ apache('matomo.conf',
    name='matomo.conf',
    servername='mon.opendataservices.coop',
    https='yes') }}

# This is needed so salt Mysql operations can work
python3-mysqldb:
  pkg.installed


piwik:
  mysql_user.present:
    - host: localhost
    - password: {{ pillar.piwik.mysql_password }}
    - require:
      - pkg: mysql-server
  mysql_database.present:
    - require:
      - pkg: mysql-server
  mysql_grants.present:
    - grant: all privileges
    - database: piwik.*
    - user: piwik
    - require:
      - pkg: mysql-server

# Give PHP more resources
/etc/php/7.4/apache2/conf.d/99matomo.ini:
  file.managed:
    - source: salt://matomo/php-apache-conf.ini

# Cron - add entry
/etc/cron.d/matomo:
  file.managed:
    - source: salt://matomo/cron

# Make sure cron user can write to log file
/home/matomo/cron-matomo.log:
  file.managed:
    - user: www-data
    - group: www-data

# File permissions in app
# Need generally open for web server to read, then some specific locations need more.
/home/{{ user }}/www:
  file.directory:
    - name: /home/{{ user }}/www
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - mode

/home/matomo/www/piwik/matomo.js:
  file.managed:
    - user: www-data
    - group: www-data
    - mode: 664
    - require:
      - file: /home/{{ user }}/www

/home/matomo/www/piwik/piwik.js:
  file.managed:
    - user: www-data
    - group: www-data
    - mode: 664
    - require:
      - file: /home/{{ user }}/www
