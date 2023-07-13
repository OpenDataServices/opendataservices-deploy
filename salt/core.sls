# This defines a base configuration that we want installed on all of our
# servers.

# Core packages that almost all our software will depend on
git:
  pkg.installed
{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '20.04' %}
python-apt: # required for salt to interact with apt
  pkg.installed
{% endif %}
language-pack-en: # installed by default on some server providers but not others
  pkg.installed
# Useful commands for people logging into the servers
useful-shell-commands:
  pkg.installed:
    - pkgs:
      - vim
      - tmux
      - man-db
      - psmisc # gives us killall
      - htop
# Bizarrely missing from Gandi server images
logrotate:
  pkg.installed

## Security

# Install fail2ban
fail2ban:
  pkg.installed:
    - pkgs:
      - fail2ban
      - mailutils

f2b-startup:
  service:
    - name: fail2ban
    - running
    - enable: True
    - reload: True
  require:
    - pkg: fail2ban

# Additional fail2ban config: setup email alerts when bans are triggered
# (enabled only if the jail has an appropriate action: uwsgi does, but ssh doesn't)
/etc/fail2ban/action.d/mail-whois.local:
  file.managed:
    - source: salt://fail2ban/action.d/mail-whois.local

# Disable SSH password login (use keys instead)
/etc/ssh/sshd_config:
  file.replace:
    - pattern: PasswordAuthentication yes
    - repl: PasswordAuthentication no

# reload SSH if we change the config
ssh:
  service:
    - running
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ssh/sshd_config

# Install authorized SSH public keys from the pillar
root_authorized_keys_file:
  file.managed:
    - name: /root/.ssh/authorized_keys
    - contents_pillar: authorized_keys
    - makedirs: True

{% if 'extra_authorized_keys' in pillar %}

root_authorized_keys_file_append:
  file.append:
    - name: /root/.ssh/authorized_keys
    - text: {{ salt['pillar.get']('extra_authorized_keys') | yaml_encode }}
    - require:
      - file: root_authorized_keys_file

{% endif %}

# Don't need and don't want RPC portmapper:
rpcbind:
  pkg.removed



# Set up unattended upgrades
unattended-upgrades:
  pkg.installed:
    - pkgs:
      - unattended-upgrades # this perform unattended upgrades
      {% if grains['os'] != 'Debian' %}
      # This package doesn't seem to be needed for Debian stretch, probably as
      # functionality is moved into unattended-upgrades.
      # (I've not checked if its needed for latest Ubuntu)
      - update-notifier-common # this checks whether a restart is required
      {% endif %}

/etc/apt/apt.conf.d/50unattended-upgrades:
  file.managed:
    - source: salt://apt/50unattended-upgrades
    - template: jinja

/etc/apt/apt.conf.d/10periodic:
  file.managed:
    - source: salt://apt/10periodic


# Swap file

create_swapfile:
  cmd.run:
    - name: dd if=/dev/zero of=/swapfile bs=10M count=100; chmod 600 /swapfile; mkswap /swapfile
    - creates: /swapfile

/swapfile:
  mount.swap:
    - require:
      - cmd: create_swapfile

MAILTO_root:
  cron.env_present:
    - name: MAILTO
    - value: code@opendataservices.coop
    - user: root


## Locales

uk_locale:
  locale.present:
    - name: en_GB.UTF-8

set_lc_all:
  file.append:
    - text: 'LC_ALL="en_GB.UTF-8"'
    - name: /etc/default/locale

create_root_ssh_key:
  cmd.run:
    - name: ssh-keygen -t ed25519 -C "root@{{ grains.id }}" -N '' -f /root/.ssh/id_ed25519
    - creates: /root/.ssh/id_ed25519

## Directory Backups

# To use, add a private pillar for one server only with config like this:
#
#backup_directory:
#  -  directory: /etc
#     ssh_host: server.net
#     ssh_user: user
#
# directory should be an absolute path with a slash at the start and none at the end
#
# Before use, you need to manually:
# - Add the servers ssh public key to the backup accounts .ssh/authorized_keys
# - Make a SSH connection and accept the SSH fingerprint

{% for backup_directory in pillar.backup_directory %}

backup_directory{{ backup_directory.directory | replace("/", "_") }}:
  cron.present:
    - name: ssh {{ backup_directory.ssh_user }}@{{ backup_directory.ssh_host }} mkdir -p {{ grains.id }}{{ backup_directory.directory }};  rsync -a --delete {{ backup_directory.directory }}/* {{ backup_directory.ssh_user }}@{{ backup_directory.ssh_host }}:{{ grains.id }}{{ backup_directory.directory }}/
    - identifier: backup_directory{{ backup_directory.directory | replace("/", "_") }}
    - user: root
    - minute: 0
    - hour: {{ loop.index }}

{% endfor %}
