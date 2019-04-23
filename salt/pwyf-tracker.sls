{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'pwyf_tracker' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/pwyf/aid-transparency-tracker.git' %}

# libapache2-mod-wsgi-py3
# gettext

include:
  - core
  - apache
  - uwsgi
  - postgres10
{% if 'https' in pillar.pwyf_tracker %}  - letsencrypt{% endif %}

pwyf_tracker-deps:
    apache_module.enabled:
      - name: proxy
      - watch_in:
        - service: apache2
    pkgrepo.managed:
      - ppa: deadsnakes/ppa
      - require_in:
        pkg: pwyf_tracker-deps
    pkg.installed:
      - pkgs:
        - python-pip
        - uwsgi-plugin-python3
        - python3.7
        - npm
      - watch_in:
        - service: apache2
        - service: uwsgi

proxy_http:
    apache_module.enabled:
      - watch_in:
        - service: apache2

remoteip:
    apache_module.enabled:
      - watch_in:
        - service: apache2

pipenv:
  pip.installed:
    - user: {{ user }}
    - require:
      - pkg: pwyf_tracker-deps

pwyf_tracker:
  postgres_user.present:
    - password: {{ pillar.pwyf_tracker.postgres.pwyf_tracker.password }}

  postgres_database.present: []

{% macro pwyf_tracker(name, giturl, branch, flaskdir, user, uwsgi_port, servername=None) %}


{% set extracontext %}
site_url: pillar.pwyf_tracker.site_url
flaskdir: {{ flaskdir }}
{% if grains['osrelease'] == '16.04' %}{# or grains['osrelease'] == '18.04' %}#}
uwsgi_port: null
{% else %}
uwsgi_port: {{ uwsgi_port }}
{% endif %}
branch: {{ branch }}
bare_name: {{ name }}
{% endset %}

{% if 'https' in pillar.pwyf_tracker %}
{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername if servername else branch+'.'+grains.fqdn,
    serveraliases=[ branch+'.'+grains.fqdn ] if servername else [],
    https=pillar.pwyf_tracker.https) }}
{% else %}
{{ apache(user+'.conf',
    name=name+'.conf',
    servername=servername if servername else 'default',
    extracontext=extracontext) }}
{% endif %}

{{ uwsgi(user+'.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

{{ giturl }}{{ flaskdir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - target: {{ flaskdir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

/home/{{ user }}/.local/bin/pipenv install:
  cmd.run:
    - runas: {{ user }}
    - cwd: {{ flaskdir }}
    - require:
      - pkg: pwyf_tracker-deps
      - pip: pipenv
      - git: {{ giturl }}{{ flaskdir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

npm install:
  cmd.run:
    - runas: {{ user }}
    - cwd: {{ flaskdir }}
    - require:
      - pkg: pwyf_tracker-deps
      - git: {{ giturl }}{{ flaskdir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

npm run build:
  cmd.run:
    - runas: {{ user }}
    - cwd: {{ flaskdir }}
    - require:
      - cmd: npm install
    - watch_in:
      - service: apache2
    
{{ flaskdir }}/.env:
  file.managed:
    - source: salt://env/pwyf_tracker.env
    - template: jinja
    - context:
        {{ extracontext | indent(8) }}

pipenv run flask db upgrade:
  cmd.run:
    - runas: {{ user }}
    - cwd: {{ flaskdir }}
    - require:
      - file: {{ flaskdir }}/.env
      - postgres_user: pwyf_tracker
      - postgres_database: pwyf_tracker
    - watch_in:
      - service: apache2

pipenv run flask createsuperuser:
  cmd.run:
    - runas: {{ user }}
    - cwd: {{ flaskdir }}
    - require:
      - cmd: pipenv run flask db upgrade
    - watch_in:
      - service: apache2
{% endmacro %}

MAILTO:
  cron.env_present:
    - value: code@opendataservices.coop
    - user: pwyf_tracker

{{ pwyf_tracker(
    name='pwyf_tracker',
    giturl=giturl,
    branch='master',
    flaskdir='/home/'+user+'/pwyf_tracker/',
    uwsgi_port=3032,
    servername=pillar.pwyf_tracker.servername if 'servername' in pillar.pwyf_tracker else None,
    user=user) }}

{#
{% if 'extra_pwyf_tracker_branches' in pillar %}
{% for branch in pillar.extra_pwyf_tracker_branches %}
{{ pwyf_tracker(
    name='pwyf_tracker-'+branch.name,
    giturl=giturl,
    branch=branch.name,
    flaskdir='/home/'+user+'/pwyf_tracker-'+branch.name+'/',
    uwsgi_port=branch.uwsgi_port if 'uwsgi_port' in branch else None,
    servername=branch.servername if 'servername' in branch else None,
    user=user) }}
{% endfor %}
{% endif %}
#}
