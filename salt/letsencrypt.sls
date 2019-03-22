# letsencrypt.sls
#   installs f/k/a letsencrypt from the 16.04 repo
#   see also 'letsencrypt' macro in lib.sls
#
#  NOTES
#
#  * the version in the 16.04 repo is tragically old (0.4.1) and
#    predates renaming to certbot, nice apache support, etc

letsencrypt:
  pkg.installed

/var/www/html/.well-known:
  file.directory:
    - user: www-data
    - group: www-data

/etc/apache2/mods-enabled/ssl.load:
  file.symlink:
    - target: /etc/apache2/mods-available/ssl.load
    - makedirs: True
    - watch_in:
      - service: apache2

cron-letsencrypt-renew:
  cron.present:
    - identifier: letsencrypt-renew
    - name: letsencrypt renew --no-self-upgrade >/dev/null 2>&1
    - user: root
    - minute: random
    - hour: 7
  require:
    - pkg: letsencrypt
