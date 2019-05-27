# Set up some miscellaneous IATI code so Steven can SSH in and run it

{% from 'lib.sls' import createuser %}

{% set user = 'iati-misc' %}
{{ createuser(user) }}

include:
  - core

python-virtualenv:
  pkg.installed

https://gist.github.com/2232655f6d950413f3788be44c864151.git:
  git.latest:
    - rev: master
    - target: /home/{{ user }}/mergeindicator/
    - user: {{ user }}
    - require:
      - pkg: git

/home/{{ user }}/venv:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: salt://iati-misc/requirements.txt

/home/{{ user }}/.bashrc:
  file.managed:
    - source: salt://iati-misc/bashrc
