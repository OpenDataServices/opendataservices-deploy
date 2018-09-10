{% from 'lib.sls' import createuser %}

# Set up the server

/etc/motd:
  file.managed:
    - source: salt://system/ocdskingfisher_motd

ocdskingfisher-prerequisites  :
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

{% set user = 'ocdskingfisher' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/open-contracting/kingfisher.git' %}

{% set userdir = '/home/' + user %}
{% set ocdskingfisherdir = userdir + '/ocdskingfisher/' %}

{{ giturl }}{{ ocdskingfisherdir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - target: {{ ocdskingfisherdir }}
    - require:
      - pkg: git

{{ ocdskingfisherdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ ocdskingfisherdir }}
    - requirements: {{ ocdskingfisherdir }}requirements.txt
    - require:
      - git: {{ giturl }}{{ ocdskingfisherdir }}

  postgres_user.present:
    - name: ocdskingfisher
    - password: {{ pillar.ocdskingfisher.postgres.ocdskingfisher.password }}

  postgres_database.present:
    - name: ocdskingfisher

postgres_readonlyuser_create:
  postgres_user.present:
    - name: ocdskingfisherreadonly
    - password: {{ pillar.ocdskingfisher.postgres.ocdskingfisherreadonly.password }}

{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/ocdskingfisher_.pgpass
    - template: jinja
    - user: ocdskingfisher
    - group: ocdskingfisher
    - mode: 0400

/etc/postgresql/10/main/pg_hba.conf:
  file.managed:
    - source: salt://postgres/ocdskingfisher_pg_hba.conf

{{ userdir }}/.config/ocdskingfisher/config.ini:
  file.managed:
    - source: salt://ocdskingfisher/config.ini
    - user: ocdskingfisher
    - group: ocdskingfisher
    - makedirs: True

createdatabase-{{ ocdskingfisherdir }}:
    cmd.run:
      - name: . .ve/bin/activate; python ocdskingfisher-cli upgrade-database
      - runas: {{ user }}
      - cwd: {{ ocdskingfisherdir }}
      - require:
        - virtualenv: {{ ocdskingfisherdir }}.ve/
        - {{ userdir }}/.config/ocdskingfisher/config.ini

postgres_readonlyuser_setup_as_postgres:
    cmd.run:
      - name: >
            psql
            -c "REVOKE ALL ON schema public FROM public; GRANT ALL ON schema public TO ocdskingfisher;
            GRANT USAGE ON schema public TO ocdskingfisherreadonly; GRANT SELECT ON ALL TABLES IN SCHEMA public TO ocdskingfisherreadonly;"
            ocdskingfisher
      - runas: postgres
      - cwd: {{ ocdskingfisherdir }}
      - require:
        - {{ userdir }}/.pgpass
        - postgres_readonlyuser_create
        - {{ ocdskingfisherdir }}.ve/

postgres_readonlyuser_setup_as_user:
    cmd.run:
      - name: psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ocdskingfisherreadonly;" ocdskingfisher
      - runas: {{ user }}
      - cwd: {{ ocdskingfisherdir }}
      - require:
        - {{ userdir }}/.pgpass
        - postgres_readonlyuser_create
        - {{ ocdskingfisherdir }}.ve/
        - postgres_readonlyuser_setup_as_postgres

