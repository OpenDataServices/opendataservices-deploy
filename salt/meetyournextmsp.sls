{% from 'lib.sls' import createuser, apache, uwsgi  %}

{% set user = 'meetyournextmsp' %}
{{ createuser(user) }}

include:
  - apache
  - uwsgi
  - letsencrypt

meetyournextmsp-deps:
    apache_module.enabled:
      - name: proxy proxy_uwsgi
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
        - gettext

/home/{{ user }}/data:
  git.latest:
    - name: https://github.com/meetyournextmsp/data-2021.git
    - rev: main
    - target: /home/{{ user }}/data
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git


/home/{{ user }}/eventtig:
  git.latest:
    - name: https://github.com/eventtig/eventtig-gitengine.git
    - rev: main
    - target: /home/{{ user }}/eventtig
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git


/home/{{ user }}/website:
  git.latest:
    - name: https://github.com/meetyournextmsp/website.git
    - rev: main
    - target: /home/{{ user }}/website
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

/home/{{ user }}/eventtig/.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: /home/{{ user }}/eventtig/requirements_dev.txt
    - require:
      - git: /home/{{ user }}/eventtig


/home/{{ user }}/website/.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: /home/{{ user }}/website/requirements.txt
    - require:
      - git: /home/{{ user }}/website


{{ uwsgi(user+'.ini',
    name=user+'.ini' ) }}

{{ apache(user+'.conf',
    name=user+'.conf',
    servername='meetyournextmsp.scot',
    https='force') }}


permissions1:
  file.directory:
    - name: /home/{{ user }}/website
    - user: {{ user }}
    - dir_mode: 755
    - require:
      - git: /home/{{ user }}/website


permissions2:
  file.directory:
    - name: /home/{{ user }}/website/meetyournextmsp
    - user: {{ user }}
    - dir_mode: 755
    - require:
      - git: /home/{{ user }}/website


permissions3:
  file.directory:
    - name: /home/{{ user }}/website/meetyournextmsp/static
    - user: {{ user }}
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - mode
    - require:
      - git: /home/{{ user }}/website


/home/{{ user }}/updatedata.sh:
  file.managed:
    - source: salt://meetyournextmsp/updatedata.sh
    - user: {{ user }}
    - mode: 744


#cd /home/{{ user }}; .updatedata.sh:
#cron.present:
#    - identifier: UPDATEDATA
#    - user: {{ user }}
#    - minute: random


/home/{{ user }}/website/instance:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 755

/home/{{ user }}/website/instance/config.py:
  file.managed:
    - source: salt://meetyournextmsp/config.py
    - user: {{ user }}
    - mode: 644

# TODO run update command straight away

restart_uwsgi_service:
  cmd.run:
    - name: sleep 10; /etc/init.d/uwsgi restart
    - order: last

