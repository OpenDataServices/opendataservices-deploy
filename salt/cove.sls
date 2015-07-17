{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'cove' %}
{{ createuser(user) }}
{% set apache_conffile = user + '.conf' %}
{{ apache(apache_conffile) }}

{% set repo = 'cove' %}
{% set djangodir = '/home/'+user+'/'+repo+'/' %}
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

{{ uwsgi(user+'.ini') }}

cove-deps:
    apache_module.enable:
      - name: proxy
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - uwsgi-plugin-python3
        - gettext
      - watch_in:
        - service: apache2
        - service: uwsgi

{{ giturl }}:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: /home/{{ user }}/{{ repo }}/
    - user: {{ user }}
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

set_lc_all:
  file.append:
    - text: 'LC_ALL="en_GB.UTF-8"'
    - name: /etc/default/locale

{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: /home/{{ user }}/{{ repo }}/requirements.txt
    - require:
      - git: {{ giturl }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

migrate-{{repo}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}

compilemessages-{{repo}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py compilemessages
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}

collectstatic-{{repo}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}

cd {{ djangodir }}; source .ve/bin/activate; python manage.py expire_files:
  cron.present:
    - identifier: COVE_EXPIRE_FILES
    - user: cove
    - minute: 0
    - hour: 0
