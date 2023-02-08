
#
# After installing there are some manual steps:
#
# you will have to setup SSH keys for the dokku user - see dokku ssh-keys:add
#
# you will have to set the default domain:
#   dokku domains:report --global
#   dokku domains:remove-global dokkuX.dokku.opendataservices.uk0.bigv.io
#   dokku domains:add-global dokkuX.ods.mobi
#


#--- Install Dokku from scratch

{% if not salt['file.directory_exists' ]('/var/lib/dokku') %}

dokkuconfig1:
  cmd.run:
    - name: echo "dokku dokku/web_config boolean false" | debconf-set-selections
    - runas: root

dokkuconfig2:
  cmd.run:
    - name: echo "dokku dokku/vhost_enable boolean true" | debconf-set-selections
    - runas: root

dokkuconfig3:
  cmd.run:
    - name: echo "dokku dokku/skip_key_file boolean true" | debconf-set-selections
    - runas: root

installdokku:
  cmd.run:
    - name: wget https://raw.githubusercontent.com/dokku/dokku/v0.29.4/bootstrap.sh && bash bootstrap.sh
    - runas: root
    - cwd: /tmp
    - env:
      - DOKKU_TAG: 'v0.29.4'
    - require:
      - cmd: dokkuconfig1
      - cmd: dokkuconfig2
      - cmd: dokkuconfig3

{% endif %}

#--- Install Some Plugins we like
# We can't have - require: - cmd: installdokku here as if Dokku is already installed, that state won't exist

{% if not salt['file.directory_exists' ]('/var/lib/dokku/plugins/enabled/letsencrypt') %}

letsencrypt_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git && dokku letsencrypt:cron-job --add
    - runas: root

{% else %}

letsencrypt_plugin:
  cmd.run:
    - name: dokku plugin:update letsencrypt
    - runas: root

{% endif %}

{% if not salt['file.directory_exists' ]('/var/lib/dokku/plugins/enabled/http-auth') %}

http_auth_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/dokku/dokku-http-auth.git
    - runas: root

{% else %}

http_auth_plugin:
  cmd.run:
    - name: dokku plugin:update http-auth
    - runas: root

{% endif %}

{% if not salt['file.directory_exists' ]('/var/lib/dokku/plugins/enabled/redis') %}

redis_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/dokku/dokku-redis.git redis
    - runas: root

{% else %}

redis_plugin:
  cmd.run:
    - name: dokku plugin:update redis
    - runas: root

{% endif %}

{% if not salt['file.directory_exists' ]('/var/lib/dokku/plugins/enabled/postgres') %}

postgres_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
    - runas: root

{% else %}

postgres_plugin:
  cmd.run:
    - name: dokku plugin:update postgres
    - runas: root

{% endif %}

# Dokkusd only needed on dev servers currently - it's one use is to clear out old branches
{% if 'dev' in grains['fqdn'] %}
{% if not salt['file.directory_exists' ]('/var/lib/dokku/plugins/enabled/dokkusd') %}

dokkusd_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/OpenDataServices/dokkusd-plugin.git  --name dokkusd
    - runas: root

{% else %}

# should be update, but that is failing at the moment TODO sort out

{% endif %}
{% endif %}

{% if 'vs.mythic-beasts.com' in grains['fqdn'] %}

# On Mythic Beasts was seeing an error where containers only got IPv6 DNS servers and then they couldn't see anything on the internet
# Fixed by explicitly telling Docker to use Google DNS
# TODO this should restart docker before it takes affect, for now letting manual restart or server restart do it

/etc/docker/daemon.json:
    file.managed:
        - source: salt://dokku/docker-daemon-with-google-dns.json
        - makedirs: True

{% endif %}

{% if grains['lsb_distrib_release']=='22.04' %}

# Without this the HTTP auth plugin won't work as nginx can't see the passwd file
# https://github.com/dokku/dokku-http-auth/issues/15
user-dokku-home-directory-permissions:
  file.directory:
    - name: /home/dokku
    - mode: 0755

{% endif %}

