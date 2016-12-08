# certbot.sls
#  installs certbot-auto
#  see also 'certbot' macro in lib.sls
#
#  NOTES
#
#  * We would prefer to use a proper distro repo instead of this :(
#  * We grab a specific commit 'ce4e00569e6d8ed3d51c5a078d4281bec5f8e5f0'
#    from the upstream git repo -- salt wants a stable source-hash
#    to be cool about downloading from the net, and frankly I agree.
#    (See https://github.com/certbot/certbot/releases where 'ce4e005'
#    is the commit hash of tag v0.9.3)
#  * certbot-auto downloads and installs a shedload of backport stuff via
#    apt-get: augeas python python-dev virtualenv gcc dialog libssl-dev
#             libffi-dev ca-certificates
#    and also python deps into /root/.local/share/letsencrypt/

certbot-load-ssl:
  file.symlink:
    - name:   /etc/apache2/mods-enabled/ssl.load
    - target: /etc/apache2/mods-available/ssl.load
    - makedirs: True
    - watch_in:
      - service: apache2

certbot-auto:
  file.managed:
    - name: /root/certbot-auto
    - source: https://raw.githubusercontent.com/certbot/certbot/ce4e00569e6d8ed3d51c5a078d4281bec5f8e5f0/certbot-auto
    - source_hash: sha256=6249576909473ffddd945f8574b4035fd4a2be0323f748a650565ae32b9d4971
    - mode: 755

certbot-initialise:
  cmd.run:
    - name: /root/certbot-auto plugins --non-interactive 1>/dev/null
    - require:
      - file: /root/certbot-auto
    - creates:
      - /root/.local/share/letsencrypt/

cron-certbot-renew:
  cron.present:
    - identifier: certbot-renew
    - name: /root/certbot-auto renew --quiet --no-self-upgrade
    - user: root
    - minute: random
    - hour: 7
