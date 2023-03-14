
{% from 'lib.sls' import createuser, apache, uwsgi, removeapache, removeuwsgi %}

include:
  - core
  - apache
  - uwsgi
  - letsencrypt


##################################################################### Web App


lillorgid-deps:
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
      - watch_in:
        - service: apache2
        - service: uwsgi


{% set user = 'lillorgidwebapp' %}
{{ createuser(user, world_readable_home_dir='yes') }}


{% macro lillorgid(name, giturl, branch, codedir, webserverdir, user, uwsgi_port, servername, https, azure_postgres_connection_string) %}


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

#  A Directory for web server to serve
{{ webserverdir }}:
  file.directory:
    - user: www-data
    - group: www-data
    - makedirs: True

# WSGI file for uWSGI to use
{{ codedir }}/wsgi.py:
  file.managed:
    - source: salt://lillorgid/wsgi.py
    - require:
      - virtualenv: {{ codedir }}.ve/

{% set extracontext %}
user: {{ user }}
codedir: {{ codedir }}
lillorgid_name: {{ name }}
uwsgi_port: {{ uwsgi_port }}
webserverdir: {{ webserverdir }}
azure_postgres_connection_string: {{ azure_postgres_connection_string }}
{% endset %}

{{ apache('lillorgid.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername ,
    https=https) }}

{{ uwsgi('lillorgid.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

{% endmacro %}


{{ lillorgid(
    name='lillorgid',
    giturl='https://github.com/OpenDataServices/opendataservices-lill-orgid-web-app.git',
    branch='live',
    codedir='/home/'+user+'/webapp/',
    webserverdir='/home/'+user+'/webapp/webserverdir/',
    user=user,
    uwsgi_port=3032,
    servername='lill.org-id.guide',
    https='no',
    azure_postgres_connection_string=pillar.lillorgid.azure_postgres_connection_string
       ) }}
