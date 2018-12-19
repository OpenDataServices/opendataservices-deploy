{% from 'lib.sls' import createuser %}

# Set up the server
# ... these bits are in ocdskingfisher.sls
# ... /etc/motd:

ocdskingfisherprocess-prerequisites  :
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

{% set user = 'ocdskfp' %}
{{ createuser(user) }}
{% set giturl = 'https://github.com/open-contracting/kingfisher-process.git' %}

{% set userdir = '/home/' + user %}
{% set ocdskingfisherdir = userdir + '/ocdskingfisherprocess/' %}

{{ giturl }}{{ ocdskingfisherdir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - branch: dev ### This is temporary - it will soon be set to master and not changed
    - rev: dev ### This is temporary - it will soon be set to master and not changed
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
    - name: ocdskfp
    - password: {{ pillar.ocdskingfisherprocess.postgres.ocdskfp.password }}

  postgres_database.present:
    - name: ocdskingfisherprocess

kfp_postgres_readonlyuser_create:
  postgres_user.present:
    - name: ocdskfpreadonly
    - password: {{ pillar.ocdskingfisherprocess.postgres.ocdskfpreadonly.password }}


{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/ocdskingfisher_process_.pgpass
    - template: jinja
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0400

# This is in ocdskingfisher.sls
#/etc/postgresql/10/main/pg_hba.conf:
#  file.managed:
#    - source: salt://postgres/ocdskingfisher_pg_hba.conf

{{ userdir }}/.config/ocdskingfisher-process/config.ini:
  file.managed:
    - source: salt://ocdskingfisherprocess/config.ini
    - template: jinja
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

createdatabase-{{ ocdskingfisherdir }}:
    cmd.run:
      - name: . .ve/bin/activate; python ocdskingfisher-process-cli upgrade-database
      - runas: {{ user }}
      - cwd: {{ ocdskingfisherdir }}
      - require:
        - virtualenv: {{ ocdskingfisherdir }}.ve/
        - {{ userdir }}/.config/ocdskingfisher-process/config.ini

kfp_postgres_readonlyuser_setup_as_postgres:
    cmd.run:
      - name: >
            psql
            -c "REVOKE ALL ON schema public FROM public; GRANT ALL ON schema public TO ocdskfp;
            GRANT USAGE ON schema public TO ocdskfpreadonly; GRANT SELECT ON ALL TABLES IN SCHEMA public TO ocdskfpreadonly;"
            ocdskingfisherprocess
      - runas: postgres
      - cwd: {{ ocdskingfisherdir }}
      - require:
        - {{ userdir }}/.pgpass
        - kfp_postgres_readonlyuser_create
        - {{ ocdskingfisherdir }}.ve/

kfp_postgres_readonlyuser_setup_as_user:
    cmd.run:
      - name: psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ocdskfpreadonly;" ocdskingfisherprocess
      - runas: {{ user }}
      - cwd: {{ ocdskingfisherdir }}
      - require:
        - {{ userdir }}/.pgpass
        - kfp_postgres_readonlyuser_create
        - {{ ocdskingfisherdir }}.ve/
        - kfp_postgres_readonlyuser_setup_as_postgres

