
#
# After installing there are some manual steps:
#
# you will have to setup SSH keys for the dokku user - see dokku ssh-keys:add
#
# you will have to set the default domain:
#   dokku domains:remove-global dokkuX.dokku.opendataservices.uk0.bigv.io
#   dokku domains:add-global dokkuX.ods.mobi


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
    - name: wget https://raw.githubusercontent.com/dokku/dokku/v0.22.9/bootstrap.sh && bash bootstrap.sh
    - runas: root
    - cwd: /tmp
    - env:
      - DOKKU_TAG: 'v0.22.9'
    - require:
      - cmd: dokkuconfig1
      - cmd: dokkuconfig2
      - cmd: dokkuconfig3

{% endif %}

#--- Install Some Plugins we like

{% if not salt['file.directory_exists' ]('/var/lib/dokku/plugins/enabled/letsencrypt') %}

letsencrypt_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
    - runas: root

{% endif %}

#--- Install our deployer app

/var/lib/dokku/data/storage/deployer/deploy-logs:
  file.directory:
    - user: dokku
    - group: dokku
    - makedirs: true
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode

/var/lib/dokku/data/storage/deployer/repos:
  file.directory:
    - user: dokku
    - group: dokku
    - makedirs: true
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode

/var/lib/dokku/data/storage/deployer/settings:
  file.directory:
    - user: dokku
    - group: dokku
    - makedirs: true
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode

/var/lib/dokku/data/storage/deployer/ssh:
  file.directory:
    - user: dokku
    - group: dokku
    - makedirs: true
    - dir_mode: 700
    - file_mode: 600
    - recurse:
      - user
      - group
      - mode


{% if not salt['file.file_exists' ]('/var/lib/dokku/data/storage/deployer/ssh/id_rsa') %}

generate_deployer_key:
  cmd.run:
    - name: ssh-keygen -t rsa -b 4096 -C "dokku-branch-deployer" -f /var/lib/dokku/data/storage/deployer/ssh/id_rsa -q -N ""
    - runas: dokku
    - require:
      - file: /var/lib/dokku/data/storage/deployer/ssh

{% endif %}

/var/lib/dokku/data/storage/deployer/settings/settings.yaml:
  file.managed:
    - source: {{ pillar.dokku_deployer.settings_file }}
    - template: jinja
    - user: dokku
    - group: dokku
    - require:
      - file: /var/lib/dokku/data/storage/deployer/settings
