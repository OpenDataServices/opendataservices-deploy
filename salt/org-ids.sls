{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'org-ids' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/org-ids.git' %}

include:
  - core
  - apache
  - uwsgi

org-ids-deps:
    apache_module.enabled:
      - name: proxy {% if grains['osrelease'] == '20.04' %}proxy_uwsgi{% endif %}
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
        - python-pip
        - python-virtualenv
{% endif %}
{% if grains['osrelease'] == '20.04' %}
        - python3-pip
        - python3-virtualenv
{% endif %}
        - uwsgi-plugin-python3
        - python3-dev
      - watch_in:
        - service: apache2
        - service: uwsgi

{% macro org_ids(name, branch, giturl, user, uwsgi_port) %}

{% set djangodir='/home/'+user+'/'+name+'/' %}

{% set extracontext %}
djangodir: {{ djangodir }}
branch: {{ branch }}
bare_name: {{ name }}
{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
uwsgi_port: null
{% else %}
uwsgi_port: {{ uwsgi_port }}
{% endif %}
{% endset %}

{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext) }}

{{ uwsgi(user+'.ini',
    name=name+'.ini',
    extracontext=extracontext) }}

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

{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
# Install the latest version of pip first
# This is necessary to download linux wheels, which avoids building C code
{{ djangodir }}.ve/-pip:
  virtualenv.managed:
    - name: {{ djangodir }}.ve/
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - pip_pkgs: pip==8.1.2
    - require:
      - pkg: org-ids-deps
      - git: {{ giturl }}{{ djangodir }}

# Then install the rest of our requirements
{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ djangodir }}requirements.txt
    - require:
      - virtualenv: {{ djangodir }}.ve/-pip
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2


{% endif %}

{% if grains['osrelease'] == '20.04' %}
# Then install the rest of our requirements
{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - require:
      - git: {{ giturl }}{{ djangodir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

# This should ideally be in virtualenv.managed but we get an error if we do that
orgs-ids-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{% endif %}

migrate-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
{% if grains['osrelease'] == '20.04' %}
      - cmd: orgs-ids-install-python-packages
{% endif %}
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

#compilemessages-{{name}}:
#  cmd.run:
#    - name: . .ve/bin/activate; python manage.py compilemessages
#    - user: {{ user }}
#    - cwd: {{ djangodir }}
#    - require:
#      - virtualenv: {{ djangodir }}.ve/
#{% if grains['osrelease'] == '20.04' %}
#      - cmd: orgs-ids-install-python-packages
#{% endif %}
#    - onchanges:
#      - git: {{ giturl }}{{ djangodir }}

collectstatic-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
{% if grains['osrelease'] == '20.04' %}
      - cmd: orgs-ids-install-python-packages
{% endif %}
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{{ djangodir }}static/:
  file.directory:
    - file_mode: 644
    - dir_mode: 755
    - recurse:
      - mode
    - require:
      - cmd: collectstatic-{{name}}
    - user: {{ user }}
    - group: {{ user }}

{{ djangodir }}:
  file.directory:
    - dir_mode: 755
    - require:
      - cmd: collectstatic-{{name}}
    - user: {{ user }}
    - group: {{ user }}

{% endmacro %}


{{ org_ids(
    name='org-ids',
    branch=pillar.org_ids.default_branch,
    giturl=giturl,
    user=user,
    uwsgi_port=pillar.org_ids.uwsgi_port
    ) }}

{% for branch in pillar.extra_org_ids_branches %}
{{ org_ids(
    name='org-ids-'+branch.name,
    branch=branch.name,
    giturl=giturl,
    user=user,
    uwsgi_port=branch.uwsgi_port
    ) }}
{% endfor %}
