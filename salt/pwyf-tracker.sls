# After installing this server for the first time, you must run the steps from
# `flask setup` onwards on:
# https://github.com/pwyf/aid-transparency-tracker/#installation

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

{% if 'https' in pillar.pwyf_tracker %}  - letsencrypt{% endif %}

pwyf_tracker-deps:
    apache_module.enabled:
      - name: proxy
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python3-pip
        - python3-virtualenv
        - uwsgi-plugin-python3
        - sqlite3
      - watch_in:
        - service: apache2
        - service: uwsgi

pwyf_tracker-uwsgi:
    apache_module.enabled:
      - name: proxy_uwsgi
      - watch_in:
        - service: apache2
      - require:
        - pkg: pwyf_tracker-deps

remoteip:
    apache_module.enabled:
      - watch_in:
        - service: apache2


{% macro pwyf_tracker(name, giturl, branch, flaskdir, user, uwsgi_port, servername=None) %}

{% set extracontext %}
secret_key: {{ pillar.pwyf_tracker.secret_key }}
flaskdir: {{ flaskdir }}
{% if grains['osrelease'] == '16.04' %}{# or grains['osrelease'] == '18.04' %}#}
uwsgi_port: null
{% else %}
uwsgi_port: {{ uwsgi_port }}
{% endif %}
branch: {{ branch }}
bare_name: {{ name }}
{% endset %}

{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername,
    https=pillar.pwyf_tracker.https) }}

{# apache(user+'.dev.conf',
    name=name+'.dev.conf',
    extracontext=extracontext,
    servername=pillar.pwyf_tracker.devname,
    https=pillar.pwyf_tracker.https) #}

{{ uwsgi('pwyf-tracker.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

{{ giturl }}{{ flaskdir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - branch: {{ branch }}
    - target: {{ flaskdir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - force_checkout: True
    - submodules: True
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

{{ flaskdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - require:
      - pkg: pwyf_tracker-deps
      - git: {{ giturl }}{{ flaskdir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

# THIS SHOULD IDEALLY BE IN virtualenv.managed BUT WE GET A PERMISSION ERROR IF WE DO THAT
install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user }}
    - cwd: {{ flaskdir }}
    - require:
      - virtualenv: {{ flaskdir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ flaskdir }}

{{ flaskdir }}/config.py:
  file.managed:
    - user: {{ user }}
    - source: salt://pwyf-tracker/config.py
    - template: jinja
    - context:
        {{ extracontext | indent(8) }}

{{ flaskdir }}//data:
  file.directory:
    - user: {{ user }}
    - makedirs: True

{{ flaskdir }}/sample_work:
  file.directory:
    - user: {{ user }}
    - makedirs: True

{{ flaskdir }}/results:
  file.directory:
    - user: {{ user }}
    - makedirs: True

{% endmacro %}

MAILTO:
  cron.env_present:
    - value: code@opendataservices.coop
    - user: pwyf_tracker

{{ pwyf_tracker(
    name='pwyf_tracker_original',
    giturl=giturl,
    branch=pillar.pwyf_tracker.branch if 'branch' in pillar.pwyf_tracker else 'main',
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


/home/{{ user }}/backups:
  file.directory:
    - user: {{ user }}
    - makedirs: True

/home/{{ user }}/backup.sh:
  file.managed:
    - user: {{ user }}
    - source: salt://pwyf-tracker/backup.sh
    - mode: '0755'
    - template: jinja
  cron.present:
    - identifier: BACKUP
    - user: {{ user }}
    - minute: 1 
    - hour: 1

