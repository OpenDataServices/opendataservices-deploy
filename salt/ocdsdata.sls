caddy-pkgrepo:
  pkgrepo.managed:
    - humanname: Caddy
    - name: 'deb https://dl.cloudsmith.io/public/caddy/stable/deb/debian "any-version" main'
    - file: /etc/apt/sources.list.d/caddy-stable.list
    - require_in:
      - pkg: ocdsdata-deps
    - gpgcheck: 1
    - key_url: https://dl.cloudsmith.io/public/caddy/stable/gpg.key


ocdsdata-deps:
    pkg.installed:
      - pkgs:
        - python3-pip
        - python3-virtualenv
        - gcc
        - libxslt1-dev
        - git
        - python3-dev
        - sqlite3
        - caddy
        - s3cmd

ocdsdata-git:
    git.latest:
        - name: git@github.com:OpenDataServices/ocdsdata.git
        - rev: main
        - target: /home/airflow/ocdsdata
        - user: airflow
        - force_fetch: True
        - force_reset: True
        - submodules: True
        - require:
            - pkg: ocdsdata-deps

caddy:
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - ocdsdata-deps

/etc/caddy/Caddyfile:
  file.managed:
    - source: salt://caddy/reverse8080.caddyfile
    - template: jinja
    - require:
      - /home/airflow/ocdsdata.env
      - ocdsdata-pip


{% set airflow_ve = '/home/airflow/ocdsdata/airflow/.ve' %}

{{airflow_ve}}:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: airflow
    - system_site_packages: False
    - require:
      - git: ocdsdata-git

airflow-pip:
  cmd.wait:
    - name: "{{airflow_ve}}/bin/pip install --upgrade apache-airflow[postgres,amazon]==2.0.1 --constraint https://raw.githubusercontent.com/apache/airflow/constraints-2.0.1/constraints-3.6.txt"
    - cwd: /home/airflow/ocdsdata
    - runas: airflow
    - env_vars:
      - AIRFLOW_HOME: /home/airflow/ocdsdata/airflow
    - watch:
      - virtualenv: {{airflow_ve}}
      - git: ocdsdata-git


{% set ocdsdata_ve = '/home/airflow/ocdsdata/.ve' %}

{{ocdsdata_ve}}:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: airflow
    - system_site_packages: False
    - require:
      - git: ocdsdata-git

ocdsdata-pip:
  cmd.wait:
    - name: "{{ocdsdata_ve}}/bin/pip install -r requirements.txt"
    - cwd: /home/airflow/ocdsdata
    - runas: airflow
    - watch:
      - virtualenv: {{ocdsdata_ve}}
      - git: ocdsdata-git


/home/airflow/ocdsdata.env:
  file.managed:
    - source: salt://private/env/ocdsdata.env
    - template: jinja


/etc/systemd/system/airflow-webserver.service:
  file.managed:
    - source: salt://systemd/airflow-webserver.service
    - template: jinja
    - require:
      - /home/airflow/ocdsdata.env
      - ocdsdata-pip

airflow-webserver:
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - /etc/systemd/system/airflow-webserver.service


/etc/systemd/system/airflow-scheduler.service:
  file.managed:
    - source: salt://systemd/airflow-scheduler.service
    - template: jinja
    - require:
      - /home/airflow/ocdsdata.env
      - ocdsdata-pip


airflow-scheduler:
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - /etc/systemd/system/airflow-scheduler.service

