
{% if not salt['file.directory_exists' ]('/var/lib/dokku') %}

# Install Dokku from scratch
#
# After installing, you will have to setup SSH keys for the dokku user - see dokku ssh-keys:add
# After installing, you will have to set the default domain:
#   dokku domains:remove-global dokkuX.dokku.opendataservices.uk0.bigv.io
#   dokku domains:add-global dokkuX.ods.mobi

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

letsencrypt_plugin:
  cmd.run:
    - name: dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
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
