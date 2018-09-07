{% from 'lib.sls' import createuser, apache, uwsgi %}

include:
  - core
  - apache
  - uwsgi

ocds-extension-explorer-prerequisites  :
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
            - virtualenv
        - watch_in:
            - service: apache2
            - service: uwsgi

{% set user = 'ocdsext' %}
{{ createuser(user) }}


{% set collector_gitdir = '/home/' + user + '/collector/' %}
{% set collector_giturl = 'https://github.com/open-contracting/extensions-data-collector.git' %}

{% set explorer_gitdir = '/home/' + user + '/explorer/' %}
{% set explorer_giturl = 'https://github.com/open-contracting/extension-explorer.git' %}

{{ collector_giturl }}:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: {{ collector_gitdir }}
    - user: {{ user }}
    - submodules: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

{{ explorer_giturl }}:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: {{ explorer_gitdir }}
    - user: {{ user }}
    - submodules: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

{{ apache('ocds-extension-explorer.conf') }}

{{ uwsgi('ocds-extension-explorer.ini',
    name='ocds-extension-explorer.ini') }}

{{ collector_gitdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ collector_gitdir }}
    - requirements: {{ collector_gitdir }}requirements.txt
    - require:
      - git: {{ collector_giturl }}

{{ explorer_gitdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ explorer_gitdir }}
    - requirements: {{ explorer_gitdir }}requirements.txt
    - require:
      - git: {{ explorer_giturl }}

/home/{{ user }}/update.sh:
  file.managed:
    - source: salt://ocds-extension-explorer/update.sh
    - mode: 0744
    - user: {{ user }}

/home/{{ user }}/explorer/wsgi.py:
  file.managed:
    - source: salt://ocds-extension-explorer/wsgi.py
    - mode: 0744
    - user: {{ user }}
    - require:
      - git: {{ explorer_giturl }}

cron-ocds-extension-explorer-renew:
  cron.present:
    - identifier: ocds-extension-explorer-renew
    - name: /home/{{ user }}/update.sh > /dev/null
    - user: {{ user }}
    - minute: 0
    - hour: 9,12,15,19,20,22
