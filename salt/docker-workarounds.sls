# This file contains work arounds for our servers running docker swarm
# There is no salt file for the Docker install, as we use a Bytemark VM image
# which comes with docker installed.
# See the roster for more deploy information for our docker servers.

# Install ufw
ufw:
  pkg:
    - installed
  service:
    - running
    - enable: True

# Add some rules
ufw allow ssh:
  cmd.run

ufw allow http:
  cmd.run

# Enable the firewall
# This is different from enable:True above.
# That makes sure the process is running, whereas this makes sure the firewall
# is actually turned on. 
yes | ufw enable:
  cmd.run

# Use socat to work around the lack of convenient IPv6 support in docker swarm.
socat:
  pkg:
    - installed

/etc/systemd/system/socat-docker-ipv6.service:
  file.managed:
    - source: salt://systemd/socat-docker-ipv6.service

socat-docker-ipv6:
  service:
    - running
    - enable: True
    - require:
      - /etc/systemd/system/socat-docker-ipv6.service
