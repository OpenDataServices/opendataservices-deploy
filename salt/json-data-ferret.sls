# For a live deploy, please follow the instructions at https://cove.readthedocs.io/en/latest/deployment/
{% from 'lib.sls' import createuser, apache, uwsgi, removeapache, removeuwsgi %}

{% set user = 'jsondataferret' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/json-data-ferret.git' %}

include:
  - core
  - apache
  - uwsgi

json-data-ferret-deps:
    apache_module.enabled:
      - name: proxy proxy_uwsgi
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
        - postgresql
        - libpq-dev
      - watch_in:
        - service: apache2
        - service: uwsgi


{% macro jsondataferret(name, giturl, branch, djangodir, user, uwsgi_port, postgres_name, postgres_user, servername=None) %}

{% set extracontext %}
djangodir: {{ djangodir }}
uwsgi_port: {{ uwsgi_port }}
branch: {{ branch }}
bare_name: {{ name }}
postgres_user: {{ postgres_user }}
postgres_name: {{ postgres_name }}
allowedhosts: {{ servername }}
{% endset %}

{{ apache('jsondataferret.conf',
    name=name+'.conf',
    servername=servername if servername else 'default',
    extracontext=extracontext) }}

{{ uwsgi('jsondataferret.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

{{ giturl }}{{ djangodir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - target: {{ djangodir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

# virtualenv.managed not working; put a quick hack in for now

createvirtualenv-{{name}}:
  cmd.run:
    - name: virtualenv .ve -p python3
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - unless: file.path_exists_glob('{{ djangodir }}/.ve')

{{ djangodir }}.ve/:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - pkg: json-data-ferret-deps
      - git: {{ giturl }}{{ djangodir }}
      - cmd: createvirtualenv-{{name}}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

{{ djangodir }}database:
  postgres_user.present:
    - name: '{{ postgres_user }}'
    - password: '{{ pillar.jsondataferret.postgres_password }}'
    - require:
      - pkg: json-data-ferret-deps

  postgres_database.present:
    - name: '{{ postgres_name }}'
    - owner: '{{ postgres_user }}'
    - require:
      - pkg: json-data-ferret-deps

migrate-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py migrate --noinput
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - cmd: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{% endmacro %}

{% for install in pillar.json_data_ferret_installs %}
{{ jsondataferret(
    name='jsondataferret-'+install.name,
    giturl=giturl,
    branch=install.branch,
    djangodir='/home/'+user+'/jsondataferret-'+install.name+'/',
    uwsgi_port=install.uwsgi_port if 'uwsgi_port' in install else None,
    servername=install.servername if 'servername' in install else None,
    postgres_user=install.postgres_user,
    postgres_name=install.postgres_name,
    user=user) }}
{% endfor %}
