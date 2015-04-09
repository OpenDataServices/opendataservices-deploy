# This defines a base configuration that we want installed on all of our
# servers.

# Core packages that almost all our software will depend on
git:
  pkg.installed

# Useful commands for people logging into the servers
useful-shell-commands:
  pkg.installed:
    - pkgs:
      - vim
      - tmux

## Security
# Install fail2ban
fail2ban:
  pkg.installed

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

/etc/apt/apt.conf.d/10periodic:
  file.managed:
    - source: salt://apt/10periodic
