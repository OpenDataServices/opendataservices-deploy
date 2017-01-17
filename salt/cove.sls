{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'cove' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/cove.git' %}

# libapache2-mod-wsgi-py3
# gettext

include:
  - core
  - apache
  - uwsgi
{% if 'https' in pillar.cove %}  - letsencrypt{% endif %}

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
        - gettext
      - watch_in:
        - service: apache2
        - service: uwsgi

remoteip:
    apache_module.enable:
      - watch_in:
        - service: apache2

set_lc_all:
  file.append:
    - text: 'LC_ALL="en_GB.UTF-8"'
    - name: /etc/default/locale


{% macro cove(name, giturl, branch, djangodir, user, uwsgi_port, servername=None) %}


{% set extracontext %}
djangodir: {{ djangodir }}
uwsgi_port: {{ uwsgi_port }}
branch: {{ branch }}
{% endset %}

{% if 'https' in pillar.cove %}
{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername if servername else branch+'.'+grains.fqdn,
    serveraliases=[ branch+'.'+grains.fqdn ] if servername else [],
    https=pillar.cove.https) }}
{% else %}
{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext) }}
{% endif %}

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
    - force_fetch: True
    - force_reset: True
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
    - name: . .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

compilemessages-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py compilemessages
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

collectstatic-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{{ djangodir }}static/:
  file.directory:
    - user: {{ user }}
    - file_mode: 644
    - dir_mode: 755
    - recurse:
      - mode
    - require:
      - cmd: collectstatic-{{name}}

{{ djangodir }}:
  file.directory:
    - dir_mode: 755
    - require:
      - cmd: collectstatic-{{name}}

cd {{ djangodir }}; . .ve/bin/activate; SECRET_KEY="{{pillar.cove.secret_key}}" python manage.py expire_files:
  cron.present:
    - identifier: COVE_EXPIRE_FILES{% if name != 'cove' %}_{{ name }}{% endif %}
    - user: cove
    - minute: random
    - hour: 0
{% endmacro %}

MAILTO:
  cron.env_present:
    - value: code@opendataservices.coop
    - user: cove

{{ cove(
    name='cove',
    giturl=giturl,
    branch=pillar.default_branch,
    djangodir='/home/'+user+'/cove/',
    uwsgi_port=3031,
    servername=pillar.cove.servername if 'servername' in pillar.cove else None,
    user=user) }}

{% for branch in pillar.extra_cove_branches %}
{{ cove(
    name='cove-'+branch.name,
    giturl=giturl,
    branch=branch.name,
    djangodir='/home/'+user+'/cove-'+branch.name+'/',
    uwsgi_port=branch.uwsgi_port,
    servername=branch.servername if 'servername' in branch else None,
    user=user) }}
{% endfor %}
