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
        - gettext
          {% if 'iati' in pillar.cove and pillar.cove.iati %}
        - python3-dev
          {% endif %}
      - watch_in:
        - service: apache2
        - service: uwsgi

remoteip:
    apache_module.enabled:
      - watch_in:
        - service: apache2

{% macro cove(name, giturl, branch, djangodir, user, uwsgi_port, servername=None, schema_url_ocds=None, app='cove') %}


{% set extracontext %}
djangodir: {{ djangodir }}
{% if grains['osrelease'] == '16.04' %}
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
    servername=servername if servername else 'default',
    extracontext=extracontext) }}
{% endif %}

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
    - requirements: {{ djangodir }}requirements{{ '_iati' if app=='cove_iati' else '' }}.txt
    - require:
      - pkg: cove-deps
      - git: {{ giturl }}{{ djangodir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

migrate-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py migrate --noinput
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

compilemessages-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py compilemessages
    - runas: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

collectstatic-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py collectstatic --noinput
    - runas: {{ user }}
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
    giturl=pillar.cove.giturl if 'giturl' in pillar.cove else giturl,
    branch=pillar.default_branch,
    djangodir='/home/'+user+'/cove/',
    uwsgi_port=pillar.cove.uwsgi_port if 'uwsgi_port' in pillar.cove else 3031,
    servername=pillar.cove.servername if 'servername' in pillar.cove else None,
    app=pillar.cove.app if 'app' in pillar.cove else 'cove',
    user=user) }}

{% for branch in pillar.extra_cove_branches %}
{{ cove(
    name='cove-'+branch.name,
    giturl=giturl,
    branch=branch.name,
    djangodir='/home/'+user+'/cove-'+branch.name+'/',
    uwsgi_port=branch.uwsgi_port if 'uwsgi_port' in branch else None,
    servername=branch.servername if 'servername' in branch else None,
    app=branch.app if 'app' in branch else 'cove',
    user=user) }}
{% endfor %}
