# Salt formula for installing piwik
#
# This state requires some database setup. Either copy the database from an
# existing instance, or use the install wizard at:
# http://mon.opendataservices.coop/piwik/

include:
  - apache
  - php

# Download Piwik from the git repository but pick a tag for a stable release
https://github.com/piwik/piwik.git:
  git.latest:
    - rev: 2.13.1
    - target: /var/www/html/piwik/
    - submodules: True

php5-cli:
  pkg.installed

php5-mysql:
  pkg.installed:
    - watch_in:
      - service: apache2

php5-gd:
  pkg.installed:
    - watch_in:
      - service: apache2

# Install composer (PHP package manager),
# see http://docs.saltstack.com/en/latest/ref/states/all/salt.states.composer.html
get-composer:
  cmd.run:
    - name: 'CURL=`which curl`; $CURL -sS https://getcomposer.org/installer | php'
    - unless: test -f /usr/local/bin/composer
    - cwd: /root/
    - require:
      - pkg: php5-cli

install-composer:
  cmd.wait:
    - name: mv /root/composer.phar /usr/local/bin/composer
    - cwd: /root/
    - watch:
      - cmd: get-composer

# Install piwik's dependencies
/var/www/html/piwik/:
  composer.installed:
    - no_dev: true
    - require:
      - cmd: install-composer

/var/www/html/piwik/tmp:
  file.directory:
    - user: www-data
    - group: www-data
    # Uncommented because the git state often fails for me due to
    # https://github.com/saltstack/salt/issues/22514
    #- require:
    #  - git: https://github.com/piwik/piwik.git

/var/www/html/piwik/config:
  file.directory:
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group

mysql-server:
  pkg.installed

salt-deps:
  pkg.installed:
    - pkgs:
      - python-mysqldb

piwik:
  mysql_user.present:
    - host: localhost
    - password: {{ pillar.piwik.mysql_password }}
    - require:
      - pkg: mysql-server
      - pkg: salt-deps
  mysql_database.present:
    - require:
      - pkg: mysql-server
      - pkg: salt-deps
  mysql_grants.present:
    - grant: all privileges
    - database: piwik.*
    - user: piwik
    - require:
      - pkg: mysql-server
      - pkg: salt-deps