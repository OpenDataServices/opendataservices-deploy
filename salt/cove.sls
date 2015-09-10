{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'cove' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/cove.git' %}

# libapache2-mod-wsgi-py3
# gettext

include:
  - core
  - apache

uwsgi:
  # Ensure that uwsgi is installed
  pkg:
    - installed
  # Ensure uwsgi running, and reload if any of the conf files change
  service:
    - running
    - enable: True
    - reload: True

cove-deps:
    apache_module.enable:
      - name: proxy
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
        - python3-dev
        - gettext
      - watch_in:
        - service: apache2
        - service: uwsgi

set_lc_all:
  file.append:
    - text: 'LC_ALL="en_GB.UTF-8"'
    - name: /etc/default/locale


{% macro cove(name, giturl, branch, djangodir, user, uwsgi_port) %}

{% set extracontext %}
djangodir: {{ djangodir }}
uwsgi_port: {{ uwsgi_port }}
branch: {{ branch }}
{% endset %}

{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext) }}

{{ uwsgi(user+'.ini',
    name=name+'.ini',
    djangodir=djangodir,
    port=uwsgi_port) }}

{{ giturl }}{{ djangodir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - target: {{ djangodir }}
    - user: {{ user }}
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ djangodir }}requirements.txt
    - require:
      - pkg: cove-deps
      - git: {{ giturl }}{{ djangodir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

migrate-{{name}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

compilemessages-{{name}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py compilemessages
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

collectstatic-{{name}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

cd {{ djangodir }}; source .ve/bin/activate; python manage.py expire_files:
  cron.present:
    - identifier: COVE_EXPIRE_FILES
    - user: cove
    - minute: random
    - hour: 0
{% endmacro %}

{{ cove(
    name='cove',
    giturl=giturl,
    branch=pillar.default_branch,
    djangodir='/home/'+user+'/cove/',
    uwsgi_port=3031,
    user=user) }}

{% for branch in pillar.extra_cove_branches %}
{{ cove(
    name='cove-'+branch.name,
    giturl=giturl,
    branch=branch.name,
    djangodir='/home/'+user+'/cove-'+branch.name+'/',
    uwsgi_port=branch.uwsgi_port,
    user=user) }}
{% endfor %}
