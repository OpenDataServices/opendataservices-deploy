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
      - virtualenv
      - postgresql-10
      - tmux
      - sqlite3
      - strace

{% set user = 'ocdsdata' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/open-contracting/kingfisher.git' %}

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

postgres_readonlyuser_create:
  postgres_user.present:
    - name: ocdsdatareadonly
    - password: {{ pillar.ocdsdata.postgres.ocdsdatareadonly.password }}

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

{{ userdir }}/.config/ocdsdata/config.ini:
  file.managed:
    - source: salt://ocdsdata/config.ini
    - user: ocdsdata
    - group: ocdsdata
    - makedirs: True

createdatabase-{{ ocdsdatadir }}:
    cmd.run:
      - name: . .ve/bin/activate; python ocdsdata-cli upgrade-database
      - runas: {{ user }}
      - cwd: {{ ocdsdatadir }}
      - require:
        - virtualenv: {{ ocdsdatadir }}.ve/
        - {{ userdir }}/.config/ocdsdata/config.ini

postgres_readonlyuser_setup_as_postgres:
    cmd.run:
      - name: >
            psql
            -c "REVOKE ALL ON schema public FROM public; GRANT ALL ON schema public TO ocdsdata;
            GRANT USAGE ON schema public TO ocdsdatareadonly; GRANT SELECT ON ALL TABLES IN SCHEMA public TO ocdsdatareadonly;"
            ocdsdata
      - runas: postgres
      - cwd: {{ ocdsdatadir }}
      - require:
        - {{ userdir }}/.pgpass
        - postgres_readonlyuser_create
        - {{ ocdsdatadir }}.ve/

postgres_readonlyuser_setup_as_user:
    cmd.run:
      - name: psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ocdsdatareadonly;" ocdsdata
      - runas: {{ user }}
      - cwd: {{ ocdsdatadir }}
      - require:
        - {{ userdir }}/.pgpass
        - postgres_readonlyuser_create
        - {{ ocdsdatadir }}.ve/
        - postgres_readonlyuser_setup_as_postgres

