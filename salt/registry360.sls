{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'registry360' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/ThreeSixtyGiving/registry.git' %}

# libapache2-mod-wsgi-py3
# gettext

include:
  - core
  - apache
  - uwsgi
  - letsencrypt

registry360-deps:
    apache_module.enabled:
      - name: proxy
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
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

{% macro registry360(name, giturl, branch, djangodir, user, uwsgi_port, servername=None, schema_url_ocds=None, app='registry360', serveraliases=[]) %}


{% set extracontext %}
djangodir: {{ djangodir }}
{% if grains['osrelease'] == '16.04' %}{# or grains['osrelease'] == '18.04' %}#}
uwsgi_port: null
{% else %}
uwsgi_port: {{ uwsgi_port }}
{% endif %}
branch: {{ branch }}
app: {{ app }}
bare_name: {{ name }}
{% if schema_url_ocds %}
schema_url_ocds: {{ schema_url_ocds }}
{% else %}
schema_url_ocds: null
{% endif %}
{% endset %}

# https set to no here because we don't want the default https setup found in _common.conf
{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername,
    serveraliases=serveraliases,
    https=pillar.registry360.https if 'https' in pillar.registry360 else 'no')
}}

{{ uwsgi(user+'.ini',
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

{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ djangodir }}requirements.txt
    - require:
      - pkg: registry360-deps
      - git: {{ giturl }}{{ djangodir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2
{% endmacro %}

MAILTO:
  cron.env_present:
    - value: code@opendataservices.coop
    - user: registry360

{{ registry360(
    name='registry360',
    giturl=giturl,
    branch='master',
    djangodir='/home/'+user+'/registry360/',
    uwsgi_port=3032,
    servername=pillar.registry360.servername if 'servername' in pillar.registry360 else grains.fqdn,
    app=pillar.registry360.app if 'app' in pillar.registry360 else 'registry360',
    user=user) }}

{% if 'extra_registry360_branches' in pillar %}
{% for branch in pillar.extra_registry360_branches %}
{{ registry360(
    name='registry360-'+branch.name,
    giturl=giturl,
    branch=branch.name,
    djangodir='/home/'+user+'/registry360-'+branch.name+'/',
    uwsgi_port=branch.uwsgi_port if 'uwsgi_port' in branch else None,
    servername=branch + '.' + pillar.registry360.servername if 'servername' in pillar.registry360 else branch + 'registry360' + '.' + grains.fqdn,
    app=branch.app if 'app' in branch else 'registry360',
    user=user) }}
{% endfor %}
{% endif %}
