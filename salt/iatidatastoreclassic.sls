# Ubuntu 20 LTS only!
#
# Hetzner Oddness: After first install, postgres does not create it's own cluster!
# Manually run: pg_createcluster 12 main
# Then restart to make sure it is picked up correctly
#

{% from 'lib.sls' import createuser, apache, uwsgi, removeapache, removeuwsgi %}

include:
  - core
  - apache
  - uwsgi
  - letsencrypt

##################################################################### Normal User

{% set user = 'iatidatastoreclassic' %}
{{ createuser(user) }}

##################################################################### Logging User with special access
{% set user_logs = 'iatidatastoreclassic_logs' %}
{{ createuser(user_logs) }}

add_{{ user_logs }}_to_group_adm:
  group.present:
    - name: adm
    - addusers:
      - {{ user_logs }}

##################################################################### Ubuntu Dependencies

iatidatastoreclassic-deps:
    apache_module.enabled:
      - name: proxy proxy_uwsgi rewrite
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python3-pip
        - python3-virtualenv
        - uwsgi-plugin-python3
        - redis-server
        - postgresql-12
        - libpq-dev
        - gcc
        - make
        - libxml2-dev
        - libxslt1-dev
        - libevent-dev
        - python3-dev
      - watch_in:
        - service: apache2
        - service: uwsgi

##################################################################### NodeJS

iatidatastoreclassic-deps-nodejs-1:
  cmd.run:
    - name: curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    - user: root
    - creates: /etc/apt/sources.list.d/nodesource.list
    - require:
      - pkg: iatidatastoreclassic-deps


iatidatastoreclassic-deps-nodejs-2:
    pkg.installed:
      - pkgs:
        - nodejs
      - require:
        - cmd: iatidatastoreclassic-deps-nodejs-1

##################################################################### Postgres Server Tuning

/etc/postgresql/12/main/conf.d/iatidatastoreclassic.conf:
  file.managed:
    - source: salt://iatidatastoreclassic/postgres.conf
    - template: jinja
    - context:
        log_min_duration_statement: {{ pillar.iatidatastoreclassic.postgres_log_min_duration_statement if 'postgres_log_min_duration_statement' in pillar.iatidatastoreclassic else '-1' }}
        shared_buffers: {{ pillar.iatidatastoreclassic.postgres_shared_buffers if 'postgres_shared_buffers' in pillar.iatidatastoreclassic else '16GB' }}
        max_connections: {{ pillar.iatidatastoreclassic.postgres_max_connections if 'postgres_max_connections' in pillar.iatidatastoreclassic else 150 }}
    - require:
      - pkg: iatidatastoreclassic-deps

##################################################################### Continuous Deployment needs sudo

/etc/sudoers.d/{{ user }}-global:
  file.managed:
    - source: salt://iatidatastoreclassic/sudoers-global
    - template: jinja
    - context:
        user: {{ user }}

##################################################################### Matomo Import Script

{% set matomo_import_code_dir = '/home/' +  user_logs + '/matomo-import' %}
{% set matomo_import_git_url = 'https://github.com/OpenDataServices/iati-data-store-classic-matomo-import.git' %}

install_matomo_import_script:
  git.latest:
    - name: {{ matomo_import_git_url }}
    - rev: main
    - target: {{ matomo_import_code_dir }}
    - user: {{ user_logs }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

{{ matomo_import_code_dir }}/.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user_logs }}
    - system_site_packages: False
    - require:
      - pkg: iatidatastoreclassic-deps
      - git: install_matomo_import_script

# Fix permissions in virtual env
{{ matomo_import_code_dir }}-fix-ve-permissions:
  cmd.run:
    - name: chown -R {{ user_logs }}:{{ user_logs }} .ve
    - user: root
    - cwd: {{ matomo_import_code_dir }}
    - require:
      - virtualenv: {{ matomo_import_code_dir }}/.ve/

# This should ideally be in virtualenv.managed but we get an error if we do that
{{ matomo_import_code_dir }}-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user_logs }}
    - cwd: {{ matomo_import_code_dir }}
    - require:
      - pkg: iatidatastoreclassic-deps
      - virtualenv: {{ matomo_import_code_dir }}/.ve/

##################################################################### Matomo Import Logs

{% set matomo_import_logs_dir = '/home/' +  user_logs + '/logs' %}

# A logs directory to store output of processing cron
{{ matomo_import_logs_dir }}:
  file.directory:
    - user: {{ user_logs }}
    - group: {{ user_logs }}
    - makedirs: True

# Logrotate logs directory for matomo import
/etc/logrotate.d/iatidatastoreclassic-logs:
  file.managed:
    - source: salt://iatidatastoreclassic/logslogrotate
    - user: root
    - template: jinja
    - context:
        matomo_import_logs_dir: {{ matomo_import_logs_dir }}
        user_logs: {{ user_logs }}


# Apache - keep logs for longer
/etc/logrotate.d/apache2:
  file.replace:
    - pattern: rotate \d+
    - repl: rotate 90
    # If you have backups, they must be a file extension that logrotate will not try and include.
    # Otherwise logrotate will detect duplicate apache configs and crash
    - backup: False

##################################################################### Macro to install app

{% macro iatidatastoreclassic(name, giturl, branch, codedir, webserverdir, user, uwsgi_port, https, servername, postgres_name, postgres_user, postgres_password , uwsgi_as_limit, uwsgi_harakiri, uwsgi_workers, uwsgi_max_requests, uwsgi_reload_on_as, sentry_dsn, sentry_traces_sample_rate, matomo_host, matomo_siteid, matomo_token) %}

###################### Code folder & virtual env & Python Libs & more

{{ giturl }}{{ codedir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - target: {{ codedir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

{{ codedir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - require:
      - pkg: iatidatastoreclassic-deps
      - git: {{ giturl }}{{ codedir }}
    - watch_in:
      - service: apache2

# Fix permissions in virtual env
{{ codedir }}fix-ve-permissions:
  cmd.run:
    - name: chown -R {{ user }}:{{ user }} .ve
    - user: root
    - cwd: {{ codedir }}
    - require:
      - virtualenv: {{ codedir }}.ve/

# This should ideally be in virtualenv.managed but we get an error if we do that
{{ codedir }}install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user }}
    - cwd: {{ codedir }}
    - require:
      - virtualenv: {{ codedir }}.ve/

# WSGI file for uWSGI to use
{{ codedir }}/wsgi.py:
  file.managed:
    - source: salt://iatidatastoreclassic/wsgi.py
    - require:
      - virtualenv: {{ codedir }}.ve/

# An ENV file - used by worker, cron and more
{{ codedir }}/env.sh:
  file.managed:
    - source: salt://iatidatastoreclassic/env.sh
    - user: {{ user }}
    - group: {{ user }}
    - template: jinja
    - context:
        postgres_user: {{ postgres_user }}
        postgres_password: {{ postgres_password }}
        postgres_name: {{ postgres_name }}
        sentry_dsn: {{ sentry_dsn }}
        sentry_traces_sample_rate: {{ sentry_traces_sample_rate }}
        matomo_host: {{ matomo_host }}
        matomo_siteid: {{ matomo_siteid }}
        matomo_token: {{ matomo_token }}
    - require:
      - virtualenv: {{ codedir }}.ve/


######################  Database

iatidatastoreclassic-database-user-{{ name }}:
  postgres_user.present:
    - name: {{ postgres_user }}
    - password: {{ postgres_password }}
    - require:
      - pkg: iatidatastoreclassic-deps

iatidatastoreclassic-database-exists-{{ name }}:
  postgres_database.present:
    - name: {{ postgres_name }}
    - owner: {{ postgres_user }}
    - require:
      - pkg: iatidatastoreclassic-deps
      - postgres_user: iatidatastoreclassic-database-user-{{ name }}

iatidatastoreclassic-database-schema-{{ name }}:
  cmd.run:
    - name: . .ve/bin/activate; iati db upgrade
    - user: {{ user }}
    - cwd: {{ codedir }}
    - env:
      - IATI_DATASTORE_DATABASE_URL: 'postgresql://{{ postgres_user }}:{{ postgres_password }}@localhost/{{ postgres_name }}'
    - require:
      - cmd: {{ codedir }}install-python-packages
      - postgres_database: iatidatastoreclassic-database-exists-{{ name }}

######################  Redis - nothing to set up here.

######################  Docs

iatidatastoreclassic-docs-{{ name }}:
  cmd.run:
    - name: . .ve/bin/activate; iati build-docs
    - user: {{ user }}
    - cwd: {{ codedir }}
    - require:
      - cmd: {{ codedir }}install-python-packages


######################  Frontpage

iatidatastoreclassic-frontpage-{{ name }}:
  cmd.run:
    - name: . .ve/bin/activate; iati build-query-builder --deploy-url http{% if https == 'yes' or https == 'force'  %}s{% endif %}://{{ servername }}
    - user: {{ user }}
    - cwd: {{ codedir }}
    - env:
      - IATI_DATASTORE_DATABASE_URL: 'postgresql://{{ postgres_user }}:{{ postgres_password }}@localhost/{{ postgres_name }}'
      # Disable telemetry or command can freeze on a "Y/N?" prompt
      - NUXT_TELEMETRY_DISABLED: 1
    - require:
      - cmd: {{ codedir }}install-python-packages
      - cmd: iatidatastoreclassic-database-schema-{{ name }}


######################  UWSGI & Apache

#  A Directory for web server to serve
{{ webserverdir }}:
  file.directory:
    - user: www-data
    - group: www-data
    - makedirs: True

{% set extracontext %}
iatidatastoreclassic_name: {{ name }}
user: {{ user }}
uwsgi_port: {{ uwsgi_port }}
codedir: {{ codedir }}
webserverdir: {{ webserverdir }}
allowed_hosts: {{ servername }}
postgres_user: {{ postgres_user }}
postgres_password: {{ postgres_password }}
postgres_name: {{ postgres_name }}
uwsgi_as_limit: {{ uwsgi_as_limit }}
uwsgi_harakiri: {{ uwsgi_harakiri }}
uwsgi_workers: {{ uwsgi_workers }}
uwsgi_max_requests: {{ uwsgi_max_requests }}
uwsgi_reload_on_as: {{ uwsgi_reload_on_as }}
extra_apache_include_file: /etc/apache2/sites-available/{{ name }}.conf.private.include
sentry_dsn: {{ sentry_dsn }}
sentry_traces_sample_rate: {{ sentry_traces_sample_rate }}
matomo_host: {{ matomo_host }}
matomo_siteid: {{ matomo_siteid }}
matomo_token: {{ matomo_token }}
{% endset %}

/etc/apache2/sites-available/{{ name }}.conf.private.include:
  file.managed:
    - source: salt://private/iatidatastoreclassic/apache.conf
    - template: jinja
    - context:
        {{ extracontext | indent(8) }}


{{ apache('iatidatastoreclassic.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername ,
    https=https) }}

{{ uwsgi('iatidatastoreclassic.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

###################### Cron

cron-{{ name }}:
  cron.present:
    - name: cd {{ codedir }}; . .ve/bin/activate; source env.sh; iati crawler download-and-update
    - identifier: IATIDATASTORE{{ name }}DOWNLOADANDUPDATE
    - user: {{ user }}
    - minute: 0
    - hour: 6,12,18,23

{% if matomo_host %}

cron-matomo-{{ name }}:
  cron.present:
    - name: cd {{ matomo_import_code_dir }}; . .ve/bin/activate; python3 matomo-import.py /var/log/apache2/{{ name }}_access.log.1 {{ matomo_host }} {{ matomo_token }} {{ matomo_siteid }} >> {{ matomo_import_logs_dir }}/matomo-import-{{ name }}.log 2>&1
    - identifier: IATIDATASTORE{{ name }}MATOMOIMPORT
    - user: {{ user_logs }}
    - minute: 0
    - hour: 2

{% endif %}

###################### Worker


{{ codedir }}/worker.sh:
  file.managed:
    - source: salt://iatidatastoreclassic/worker.sh
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0755
    - require:
      - virtualenv: {{ codedir }}.ve/


/etc/systemd/system/iatidatastoreclassic-{{ name }}.service:
  file.managed:
    - source: salt://iatidatastoreclassic/iati-datastore.service
    - template: jinja
    - context:
        user: {{ user }}
        codedir: {{ codedir }}
        postgres_user: {{ postgres_user }}
        postgres_password: {{ postgres_password }}
        postgres_name: {{ postgres_name }}
    - require:
      - file: {{ codedir }}/worker.sh

{{name }}-service-running:
  service.running:
    - name: iatidatastoreclassic-{{ name }}
    - enable: True
    - reload: True
    - requires:
      - file: /etc/systemd/system/{{ name }}.service

###################### Continuous Deployment needs sudo

/etc/sudoers.d/{{ name }}:
  file.managed:
    - source: salt://iatidatastoreclassic/sudoers-macro
    - template: jinja
    - context:
        name: {{ name }}
        user: {{ user }}

###################### Misc

# Fix permissions in a code dir.
# Saw a bug where a egg-info directory was created in here as root, and then subsequent pip install's failed
{{ codedir }}fix-iati-datastore-permissions:
  cmd.run:
    - name: chown -R {{ user }}:{{ user }} iati_datastore
    - user: root
    - cwd: {{ codedir }}
    - require:
      - virtualenv: {{ codedir }}.ve/

{% endmacro %}

##################################################################### Run Macro Once for app

{% set defaultgiturl = 'https://github.com/codeforIATI/iati-datastore.git' %}

# This is set up in a macro - so that maybe one day we can install multiple dev versions on the same dev server.
# That isn't possible at the moment because it requires Redis, but the app has no way to configure which Redis server to use.
# Until that is fixed, only one install of this PER SERVER.
# (But it's still good to do this in a macro for clarity and the future)

{{ iatidatastoreclassic(
    name='iatidatastoreclassic',
    giturl=pillar.iatidatastoreclassic.giturl if 'giturl' in pillar.iatidatastoreclassic else defaultgiturl,
    branch=pillar.iatidatastoreclassic.gitbranch if 'gitbranch' in pillar.iatidatastoreclassic else 'main',
    codedir='/home/'+user+'/iatidatastoreclassic/',
    webserverdir='/home/'+user+'/iatidatastoreclassic-web/',
    uwsgi_port=pillar.iatidatastoreclassic.uwsgi_port if 'uwsgi_port' in pillar.iatidatastoreclassic else 3032,
    servername=pillar.iatidatastoreclassic.servername if 'servername' in pillar.iatidatastoreclassic else 'datastore.iati.opendataservices.coop',
    https=pillar.iatidatastoreclassic.https if 'https' in pillar.iatidatastoreclassic else 'no',
    postgres_name='iatidatastoreclassic',
    postgres_user='iatidatastoreclassic',
    postgres_password=pillar.iatidatastoreclassic.postgres_password if 'postgres_password' in pillar.iatidatastoreclassic else 'do-NOT-use-me-in-production',
    user=user,
    uwsgi_workers=pillar.iatidatastoreclassic.uwsgi_workers if 'uwsgi_workers' in pillar.iatidatastoreclassic else '100',
    uwsgi_max_requests=pillar.iatidatastoreclassic.uwsgi_max_requests if 'uwsgi_max_requests' in pillar.iatidatastoreclassic else '1024',
    uwsgi_reload_on_as=pillar.iatidatastoreclassic.uwsgi_reload_on_as if 'uwsgi_reload_on_as' in pillar.iatidatastoreclassic else '250',
    uwsgi_as_limit=pillar.iatidatastoreclassic.uwsgi_as_limit if 'uwsgi_as_limit' in pillar.iatidatastoreclassic else '2048',
    uwsgi_harakiri=pillar.iatidatastoreclassic.uwsgi_harakiri if 'uwsgi_harakiri' in pillar.iatidatastoreclassic else '1200',
    sentry_dsn=pillar.iatidatastoreclassic.sentry_dsn if 'sentry_dsn' in pillar.iatidatastoreclassic else '',
    sentry_traces_sample_rate=pillar.iatidatastoreclassic.sentry_traces_sample_rate if 'sentry_traces_sample_rate' in pillar.iatidatastoreclassic else '0.0',
    matomo_host=pillar.iatidatastoreclassic.matomo_host if 'matomo_host' in pillar.iatidatastoreclassic else '',
    matomo_siteid=pillar.iatidatastoreclassic.matomo_siteid if 'matomo_siteid' in pillar.iatidatastoreclassic else '',
    matomo_token=pillar.iatidatastoreclassic.matomo_token if 'matomo_token' in pillar.iatidatastoreclassic else '',
    ) }}
