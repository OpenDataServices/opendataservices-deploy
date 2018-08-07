{% from 'lib.sls' import createuser %}

# Set up the server

/etc/motd:
  file.managed:
    - source: salt://system/ocdsdata_motd

ocdsdata-prerequisites  :
  pkg.installed:
    - pkgs:
      - python-pip
      - python3-pip
      - python3-virtualenv
      - python-requests  # Needed for redash upgrades
      - python-semver # Needed for redash upgrades
      - virtualenv
      - postgresql-10
      - tmux
      - sqlite3
      - strace

{% set user = 'ocdsdata' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/open-contracting/ocdsdata.git' %}

{% set userdir = '/home/' + user %}
{% set ocdsdatadir = userdir + '/ocdsdata/' %}

{{ giturl }}{{ ocdsdatadir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - target: {{ ocdsdatadir }}
    - require:
      - pkg: git

{{ ocdsdatadir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ ocdsdatadir }}
    - requirements: {{ ocdsdatadir }}requirements.txt
    - require:
      - git: {{ giturl }}{{ ocdsdatadir }}

  postgres_user.present:
    - name: ocdsdata
    - password: {{ pillar.ocdsdata.postgres.ocdsdata.password }}

  postgres_database.present:
    - name: ocdsdata

{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/ocdsdata_.pgpass
    - template: jinja
    - user: ocdsdata
    - group: ocdsdata
    - mode: 0400

/etc/postgresql/10/main/pg_hba.conf:
  file.managed:
    - source: salt://postgres/ocdsdata_pg_hba.conf

createdatabase-{{ ocdsdatadir }}:
    cmd.run:
      - name: . .ve/bin/activate; python ocdsdata-cli upgrade-database
      - user: {{ user }}
      - cwd: {{ ocdsdatadir }}
      - require:
        - virtualenv: {{ ocdsdatadir }}.ve/

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
    - contents_pillar: ocdsdata:redash:htpasswd:contents
    - require:
      - cmd: run-redash-upgrade-nointeraction
      - cmd: /tmp/redash-bootstrap.sh

/etc/nginx/sites-available/redash:
  file.managed:
    - source: salt://nginx/ocdsdata_redash
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
