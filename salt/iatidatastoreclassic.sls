# Ubuntu 20 LTS only!

{% from 'lib.sls' import createuser, apache, uwsgi, removeapache, removeuwsgi %}

{% set user = 'iatidsc' %}
{{ createuser(user) }}


include:
  - core
  - apache
  - uwsgi
{% if 'https' in pillar.cove %}  - letsencrypt{% endif %}


iatidatastoreclassic-deps:
    apache_module.enabled:
      - name: proxy proxy_uwsgi
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
        - libxml2-dev
        - libxslt1-dev
        - libevent-dev
        - python3-dev
      - watch_in:
        - service: apache2
        - service: uwsgi


{% macro iatidatastoreclassic(name, giturl, branch, codedir, webserverdir, user, uwsgi_port, https, servername, postgres_name, postgres_user, postgres_password ) %}

# Code folder & virtual env & Python Libs

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

{{ codedir }}/wsgi.py:
  file.managed:
    - source: salt://iatidatastoreclassic/wsgi.py
    - require:
      - virtualenv: {{ codedir }}.ve/

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
    - require:
      - virtualenv: {{ codedir }}.ve/


# Database

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

# Redis - nothing to set up here.


# A Directory for web server to use

{{ webserverdir }}:
  file.directory:
    - user: www-data
    - group: www-data
    - makedirs: True

# UWSGI & Apache

{% set extracontext %}
user: {{ user }}
uwsgi_port: {{ uwsgi_port }}
codedir: {{ codedir }}
webserverdir: {{ webserverdir }}
allowed_hosts: {{ servername }}
postgres_user: {{ postgres_user }}
postgres_password: {{ postgres_password }}
postgres_name: {{ postgres_name }}
{% endset %}

{{ apache('iatidatastoreclassic.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername ,
    https=https) }}

{{ uwsgi('iatidatastoreclassic.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

# CRON

cron-{{ name }}:
  cron.present:
    - name: cd {{ codedir }}; . .ve/bin/activate; source env.sh; iati crawler download-and-update
    - identifier: IATIDATASTORE{{ name }}DOWNLOADANDUPDATE
    - user: {{ user }}}
    - minute: 0
    - hour: 4

# Worker


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

{% endmacro %}

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
    user=user) }}
