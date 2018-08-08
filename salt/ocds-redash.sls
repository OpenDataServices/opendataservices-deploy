
ocds-redash-prerequisites  :
  pkg.installed:
    - pkgs:
      - python-requests  # Needed for redash upgrades
      - python-semver # Needed for redash upgrades

run-redash-upgrade-nointeraction:
  cmd.run:
    - name: /opt/redash/current/bin/upgrade-nointeraction
    - onlyif: 'test -e /opt/redash/current/bin/upgrade-nointeraction'

/tmp/redash-bootstrap.sh:
  cmd.run:
    - name: wget -O /tmp/redash-bootstrap.sh https://raw.githubusercontent.com/getredash/redash/master/setup/ubuntu/bootstrap.sh; chmod u+x /tmp/redash-bootstrap.sh; /tmp/redash-bootstrap.sh
    - unless: 'test -e /opt/redash'

/etc/nginx/redash-htpasswd:
  file.managed:
    - contents_pillar: ocds-redash:htpasswd:contents
    - require:
      - cmd: run-redash-upgrade-nointeraction
      - cmd: /tmp/redash-bootstrap.sh

/etc/nginx/sites-available/redash:
  file.managed:
    - source: salt://nginx/redash
    - require:
      - cmd: run-redash-upgrade-nointeraction
      - cmd: /tmp/redash-bootstrap.sh

restart-nignx:
  cmd.run:
    - name: /etc/init.d/nginx restart
    - require:
      - file: /etc/nginx/redash-htpasswd
      - file: /etc/nginx/sites-available/redash

/opt/redash/current/bin/upgrade-nointeraction:
  file.managed:
    - source: salt://redash/upgrade-nointeraction
    - mode: 744
    - require:
      - cmd: run-redash-upgrade-nointeraction
      - cmd: /tmp/redash-bootstrap.sh
