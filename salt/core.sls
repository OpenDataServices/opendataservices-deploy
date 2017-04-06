# This defines a base configuration that we want installed on all of our
# servers.

# Core packages that almost all our software will depend on
git:
  pkg.installed
python-apt: # required for salt to interact with apt
  pkg.installed
# Useful commands for people logging into the servers
useful-shell-commands:
  pkg.installed:
    - pkgs:
      - vim
      - tmux
      - man-db
      - psmisc # gives us killall

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
/root/.ssh/authorized_keys:
  file.managed:
    - contents_pillar: authorized_keys
    - makedirs: True

# Set up unattended upgrades
unattended-upgrades:
  pkg.installed:
    - pkgs:
      - unattended-upgrades # this perform unattended upgrades
      - update-notifier-common # this checks whether a restart is required

/etc/apt/apt.conf.d/50unattended-upgrades:
  file.managed:
    - source: salt://apt/50unattended-upgrades
    - template: jinja

/etc/apt/apt.conf.d/10periodic:
  file.managed:
    - source: salt://apt/10periodic

{% if grains['lsb_distrib_release']=='14.04' %}
# Special config for 14.04 because it uses grub legacy, which doesn't install
# the new kernel using unattended upgrades out of the box.

debconf-utils:
  pkg.installed

grub-debconf:
  debconf.set:
    - name: grub
    - data:
        'grub/update_grub_changeprompt_threeway': {'type': 'string', 'value': 'install_new'}
    - require:
      - pkg: debconf-utils 
{% endif %}

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
