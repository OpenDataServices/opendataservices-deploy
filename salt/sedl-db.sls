{% from 'lib.sls' import createuser %}

# Set up the server

sedldb-prerequisites  :
  pkg.installed:
    - pkgs:
      - python-pip
      - python3-pip
      - python3-virtualenv
      - virtualenv
      - postgresql-10
      - tmux
      - sqlite3
      - strace

{% set user = 'sedldata' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/sedldata.git' %}

{% set userdir = '/home/' + user %}
{% set sedldatadir = userdir + '/sedldata/' %}

{{ giturl }}{{ sedldatadir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - rev: db-setup
    - force_fetch: True
    - force_reset: True
    - target: {{ sedldatadir }}
    - require:
      - pkg: git

{{ sedldatadir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ sedldatadir }}
    - requirements: {{ sedldatadir }}requirements.txt
    - require:
      - git: {{ giturl }}{{ sedldatadir }}

  postgres_user.present:
    - name: sedldata
    - password: {{ pillar.get('sedl-db').postgres.sedldata.password }}

  postgres_database.present:
    - name: sedldata
    - owner: sedldata

{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/sedl-db_.pgpass
    - template: jinja
    - user: sedldata
    - group: sedldata
    - mode: 0400

/etc/postgresql/10/main/pg_hba.conf:
  file.managed:
    - source: salt://postgres/sedl-db_pg_hba.conf

/etc/postgresql/10/main/postgresql.conf:
  file.managed:
    - source: salt://postgres/sedl-db_postgresql.conf

env_db_uri:
  environ.setenv:
    - name: DB_URI
    - value: postgresql://sedldata:{{ pillar.get('sedl-db').postgres.sedldata.password }}@localhost:5432/sedldata
    - update_minion: True

createdatabase-{{ sedldatadir }}:
  cmd.run:
    - name: . .ve/bin/activate; pip install -e .; sedldata upgrade
    - user: {{ user }}
    - cwd: {{ sedldatadir }}
    - require:
      - virtualenv: {{ sedldatadir }}.ve/
