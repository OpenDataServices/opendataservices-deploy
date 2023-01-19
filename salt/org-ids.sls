{% from 'lib.sls' import createuser, apache, uwsgi, removeapache, removeuwsgi %}

{% set user = 'org-ids' %}
{{ createuser(user, world_readable_home_dir='yes') }}

{% set giturl = 'https://github.com/OpenDataServices/org-ids.git' %}

include:
  - core
  - apache
  - uwsgi

org-ids-deps:
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
        - python3-dev
      - watch_in:
        - service: apache2
        - service: uwsgi

{{ apache('org-ids-redirect.conf',
    name='org-ids-redirect.conf',
    https='no') }}

{% macro org_ids(name, branch, giturl, user, uwsgi_port, servername, https) %}

{% set djangodir='/home/'+user+'/'+name+'/' %}

{% set extracontext %}
djangodir: {{ djangodir }}
branch: {{ branch }}
bare_name: {{ name }}
uwsgi_port: {{ uwsgi_port }}
{% endset %}

{{ apache(user+'.conf',
    name=name+'.conf',
    servername=servername,
    https=https,
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
{{ djangodir }}orgs-ids-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

migrate-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
      - cmd: {{ djangodir }}orgs-ids-install-python-packages
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

#compilemessages-{{name}}:
#  cmd.run:
#    - name: . .ve/bin/activate; python manage.py compilemessages
#    - user: {{ user }}
#    - cwd: {{ djangodir }}
#    - require:
#      - virtualenv: {{ djangodir }}.ve/
#      - cmd: {{ djangodir }}orgs-ids-install-python-packages
#    - onchanges:
#      - git: {{ giturl }}{{ djangodir }}

collectstatic-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
      - cmd: {{ djangodir }}orgs-ids-install-python-packages
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


{% macro remove_org_ids(name, djangodir, app) %}

{{ removeapache(name+'.conf') }}

{{ removeuwsgi(name+'.ini') }}

{% set djangodir='/home/'+user+'/'+name+'/' %}

{{ djangodir }}:
    file.absent

{% endmacro %}

{{ org_ids(
    name='org-ids',
    branch=pillar.org_ids.default_branch,
    giturl=giturl,
    user=user,
    uwsgi_port=pillar.org_ids.uwsgi_port,
    servername=pillar.org_ids.server_name,
    https=pillar.org_ids.https
    ) }}

{% for branch in pillar.extra_org_ids_branches %}
{{ org_ids(
    name='org-ids-'+branch.name,
    branch=branch.name,
    giturl=giturl,
    user=user,
    uwsgi_port=branch.uwsgi_port,
    servername=branch.name+'.dev.org-id.guide',
    https='no'
    ) }}
{% endfor %}

{% for branch in pillar.old_extra_org_ids_branches %}
{{ remove_org_ids(
    name='org-ids-'+branch.name
    ) }}
{% endfor %}
