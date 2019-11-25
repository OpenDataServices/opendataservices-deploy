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
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
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

pwyf_tracker:
  postgres_user.present:
    - password: {{ pillar.pwyf_tracker.postgres.pwyf_tracker.password }}

  postgres_database.present: []


{% macro pwyf_tracker(name, giturl, branch, flaskdir, user, uwsgi_port, servername=None) %}

{% set extracontext %}
site_url: {{ pillar.pwyf_tracker.site_url }}
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

{{ uwsgi('pwyf_tracker_original.ini',
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
    - requirements: {{ flaskdir }}requirements.txt
    - require:
      - pkg: pwyf_tracker-deps
      - git: {{ giturl }}{{ flaskdir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

{{ flaskdir }}/config.py:
  file.managed:
    - source: salt://pwyf-tracker/config.py
    - template: jinja
    - context:
        {{ extracontext | indent(8) }}

{{ flaskdir }}/dq/data:
  file.directory:
    - user: {{ user }}
    - source: salt://pwyf-tracker/config.py
    - makedirs: True

{{ flaskdir }}/dq/sample_work:
  file.directory:
    - user: {{ user }}
    - source: salt://pwyf-tracker/config.py
    - makedirs: True

{{ flaskdir }}/dq/results:
  file.directory:
    - user: {{ user }}
    - source: salt://pwyf-tracker/config.py
    - makedirs: True

{% endmacro %}

MAILTO:
  cron.env_present:
    - value: code@opendataservices.coop
    - user: pwyf_tracker

{{ pwyf_tracker(
    name='pwyf_tracker_original',
    giturl=giturl,
    branch='2020tracker',
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
