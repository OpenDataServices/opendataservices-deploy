# This is for Ubuntu 20

# Salt formula for installing Matomo
#
# This state requires some database setup. Either copy the database from an
# existing instance, or use the install wizard at:
# http://mon.opendataservices.coop/piwik/

include:
  - apache
  - letsencrypt


# Download Matomo from the git repository but pick a tag for a stable release
# The target is /var/www/html/piwik/.
# It is NOT /var/www/html/matomo/ because then we would have to change all clients to send data to /matomo and not /piwik
https://github.com/matomo-org/matomo.git:
  git.latest:
    - rev: 4.3.0
    - target: /var/www/html/piwik/
    - submodules: True
# Upstream matomo routinely rewrites history in their git repo, so we'll set
# this permanently
    - force_fetch: True


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

/etc/php/7.4/apache2/conf.d/99matomo.ini:
  file.managed:
    - source: salt://matomo/php-apache-conf.ini
