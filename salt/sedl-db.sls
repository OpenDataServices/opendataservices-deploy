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

{{ giturl }}{{ sedldata }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
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
    - password: {{ pillar.sedl-db.postgres.sedldata.password }}

  postgres_database.present:
    - name: sedldata

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

createdatabase-{{ sedldatadir }}:
    cmd.run:
      - name: . .ve/bin/activate; python sedldata upgrade
      - user: {{ user }}
      - cwd: {{ sedldatadir }}
      - require:
        - virtualenv: {{ sedldatadir }}.ve/
