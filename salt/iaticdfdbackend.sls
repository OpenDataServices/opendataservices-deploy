## Ubuntu 20 LTS only!
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

{% set user = 'iaticdfdbackend' %}
{{ createuser(user) }}

##################################################################### Ubuntu Dependencies

iaticdfdbackend-deps:
    apache_module.enabled:
      - name: proxy proxy_uwsgi rewrite headers
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python3-pip
        - python3-virtualenv
        - uwsgi-plugin-python3
        - postgresql-12
        - libpq-dev
        - gcc
        - make
        - libxml2-dev
        - libxslt1-dev
        - libevent-dev
        - python3-dev
        - zip
      - watch_in:
        - service: apache2
        - service: uwsgi

##################################################################### Continuous Deployment needs sudo

/etc/sudoers.d/{{ user }}-global:
  file.managed:
    - source: salt://iaticdfdbackend/sudoers-global
    - template: jinja
    - context:
        user: {{ user }}

##################################################################### Macro to install app

{% macro iaticdfdbackend(name, giturl, branch, codedir, webserverdir, user, uwsgi_port, https, servername, postgres_name, postgres_user, postgres_password , uwsgi_as_limit, uwsgi_harakiri, uwsgi_workers, uwsgi_max_requests, uwsgi_reload_on_as, sentry_dsn, sentry_traces_sample_rate) %}

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
      - pkg: iaticdfdbackend-deps
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

# An ENV file - for sentry ???
{{ codedir }}/env.sh:
  file.managed:
    - source: salt://iaticdfdbackend/env.sh
    - user: {{ user }}
    - group: {{ user }}
    - template: jinja
    - context:
        sentry_dsn: {{ sentry_dsn }}
        sentry_traces_sample_rate: {{ sentry_traces_sample_rate }}
    - require:
      - virtualenv: {{ codedir }}.ve/

# CDFS Backend config file
{{ codedir }}/config.py:
  file.managed:
    - source: salt://iaticdfdbackend/config.py
    - user: {{ user }}
    - group: {{ user }}
    - template: jinja
    - context:
        postgres_user: {{ postgres_user }}
        postgres_password: {{ postgres_password }}
        postgres_name: {{ postgres_name }}
    - require:
      - virtualenv: {{ codedir }}.ve/

# CDFS Backend download script
{{ codedir }}/download.sh:
  file.managed:
    - source: salt://iaticdfdbackend/download.sh
    - user: {{ user }}
    - mode: 755
    - require:
      - virtualenv: {{ codedir }}.ve/

######################  Logs

/home/{{ user }}/logs-{{ name }}:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

######################  Database

iaticdfdbackend-database-user-{{ name }}:
  postgres_user.present:
    - name: {{ postgres_user }}
    - password: {{ postgres_password }}
    - require:
      - pkg: iaticdfdbackend-deps

iaticdfdbackend-database-exists-{{ name }}:
  postgres_database.present:
    - name: {{ postgres_name }}
    - owner: {{ postgres_user }}
    - require:
      - pkg: iaticdfdbackend-deps
      - postgres_user: iaticdfdbackend-database-user-{{ name }}

######################  UWSGI & Apache

#  A Directory for web server to serve
{{ webserverdir }}:
  file.directory:
    - user: www-data
    - group: www-data
    - makedirs: True

{% set extracontext %}
iaticdfdbackend_name: {{ name }}
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
{% endset %}

/etc/apache2/sites-available/{{ name }}.conf.private.include:
  file.managed:
    - source: salt://private/iaticdfdbackend/apache.conf
    - template: jinja
    - context:
        {{ extracontext | indent(8) }}


{{ apache('iaticdfdbackend.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername ,
    https=https) }}

{{ uwsgi('iaticdfdbackend.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}


###################### Cron

cron-{{ name }}:
  cron.present:
    - name: cd {{ codedir }}; . .ve/bin/activate; ./update.sh > /home/{{ user }}/logs-{{ name }}/$(date +\%Y\%m\%d).log 2>&1
    - identifier: IATICDFDBACKEND{{ name }}DOWNLOADANDUPDATE
    - user: {{ user }}
    - minute: 23
    - hour: 1

###################### Database Migrations and data load

{{ codedir }}-database-setup-and-migrations:
  cmd.run:
    - name: . .ve/bin/activate; flask setup-codelists ; flask db upgrade
    - user: {{ user }}
    - cwd: {{ codedir }}
    - require:
      - virtualenv: {{ codedir }}.ve/

###################### Update


{{ codedir }}/update.sh:
  file.managed:
    - source: salt://iaticdfdbackend/update.sh
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0755
    - require:
      - virtualenv: {{ codedir }}.ve/


{% endmacro %}

##################################################################### Run Macro Once for app

{% set defaultgiturl = 'https://github.com/iati-data-access/data-backend.git' %}

# This is set up in a macro - so that maybe one day we can install multiple dev versions on the same dev server.
# That isn't possible at the moment because it requires Redis, but the app has no way to configure which Redis server to use.
# Until that is fixed, only one install of this PER SERVER.
# (But it's still good to do this in a macro for clarity and the future)

{{ iaticdfdbackend(
    name='iaticdfdbackend',
    giturl=pillar.iaticdfdbackend.giturl if 'giturl' in pillar.iaticdfdbackend else defaultgiturl,
    branch=pillar.iaticdfdbackend.gitbranch if 'gitbranch' in pillar.iaticdfdbackend else 'main',
    codedir='/home/'+user+'/iaticdfdbackend/',
    webserverdir='/home/'+user+'/iaticdfdbackend-web/',
    uwsgi_port=pillar.iaticdfdbackend.uwsgi_port if 'uwsgi_port' in pillar.iaticdfdbackend else 3033,
    servername=pillar.iaticdfdbackend.servername if 'servername' in pillar.iaticdfdbackend else 'cdfd.iati.opendataservices.coop',
    https=pillar.iaticdfdbackend.https if 'https' in pillar.iaticdfdbackend else 'no',
    postgres_name='iatidatacube',
    postgres_user='iaticdfdbackend',
    postgres_password=pillar.iaticdfdbackend.postgres_password if 'postgres_password' in pillar.iaticdfdbackend else 'do-NOT-use-me-in-production',
    user=user,
    uwsgi_workers=pillar.iaticdfdbackend.uwsgi_workers if 'uwsgi_workers' in pillar.iaticdfdbackend else '100',
    uwsgi_max_requests=pillar.iaticdfdbackend.uwsgi_max_requests if 'uwsgi_max_requests' in pillar.iaticdfdbackend else '1024',
    uwsgi_reload_on_as=pillar.iaticdfdbackend.uwsgi_reload_on_as if 'uwsgi_reload_on_as' in pillar.iaticdfdbackend else '250',
    uwsgi_as_limit=pillar.iaticdfdbackend.uwsgi_as_limit if 'uwsgi_as_limit' in pillar.iaticdfdbackend else '2048',
    uwsgi_harakiri=pillar.iaticdfdbackend.uwsgi_harakiri if 'uwsgi_harakiri' in pillar.iaticdfdbackend else '1200',
    sentry_dsn=pillar.iaticdfdbackend.sentry_dsn if 'sentry_dsn' in pillar.iaticdfdbackend else '',
    sentry_traces_sample_rate=pillar.iaticdfdbackend.sentry_traces_sample_rate if 'sentry_traces_sample_rate' in pillar.iaticdfdbackend else '0.0',
    ) }}
