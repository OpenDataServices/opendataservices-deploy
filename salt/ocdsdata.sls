{% from 'lib.sls' import createuser %}

{% set user = 'ocdsdata' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/open-contracting/ocdsdata.git' %}

{% set ocdsdatadir = '/home/' + user + '/ocdsdata/' %}


{{ giturl }}{{ ocdsdatadir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - target: {{ ocdsdatadir }}
    - require:
      - pkg: git

{{ ocdsdatadir }}.ve/-pip:
  virtualenv.managed:
    - name: {{ ocdsdatadir }}.ve/
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - pip_pkgs: pip==9.0.3
    - require:
      - git: {{ giturl }}{{ ocdsdatadir }}

{{ ocdsdatadir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ ocdsdatadir }}
    - requirements: {{ ocdsdatadir }}requirements.txt
    - require:
      - virtualenv: {{ ocdsdatadir }}.ve/-pip
      - git: {{ giturl }}{{ ocdsdatadir }}

ocdsdata:
  cmd.run:
    - name: wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

  pkgrepo.managed:
    - humanname: Postgres
    - name: deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main
    - file: /etc/apt/sources.list.d/postgres.list

  pkg.installed:
    - pkgs:
      - postgresql-10

  postgres_user.present:
    - name: ocdsdata

  postgres_database.present:
    - name: ocdsdata

