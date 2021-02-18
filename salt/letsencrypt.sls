# letsencrypt.sls
#   installs f/k/a letsencrypt from the 16.04 repo
#   see also 'letsencrypt' macro in lib.sls
#
#  NOTES
#
#  * the version in the 16.04 repo is tragically old (0.4.1) and
#    predates renaming to certbot, nice apache support, etc
#  * the version in the 18.04 repo is just a alias for certbot
#  * in 20.04 we need the actual name certbot; letsencrypt still seems to be an alias but it errors
#  * when we have got rid of our last 16.04 server we can just switch this to certbot


{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
letsencrypt:
  pkg.installed
{% endif %}
{% if grains['osrelease'] == '20.04' %}
certbot:
  pkg.installed
{% endif %}

/var/www/html/.well-known/acme-challenge:
  file.directory:
    - user: www-data
    - group: www-data
    - makedirs: True

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
