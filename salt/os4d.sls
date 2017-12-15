{% from 'lib.sls' import createuser, apache, planio_keys %}

include:
  - core
  - apache

os4d-deps:
    pkg.installed:
      - pkgs:
        - python-pip
        - python-virtualenv
        - graphviz

{% set user = 'os4d' %}
{{ createuser(user) }}
{{ planio_keys(user) }}

{% set gitdir = '/home/' + user + '/handbook/' %}
{% set giturl = 'git@opendataservices.plan.io:opendataservices/box.git' %}

{{ giturl }}:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: {{ gitdir }}
    - user: {{ user }}
    - submodules: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
      - ssh_known_hosts: {{ user }}-opendataservices.plan.io

# Set up the Apache config using macro
{{ apache('os4d-handbook.conf') }}

# Install pre requirements
{{ gitdir }}.ve/-pre:
  virtualenv.managed:
    - name: {{ gitdir }}.ve/
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ gitdir }}pre_requirements.txt
    - require:
      - pkg: org-ids-deps
      - git: {{ giturl }}

# Then install the rest of our requirements
{{ gitdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ gitdir }}requirements.txt
    - require:
      - virtualenv: {{ gitdir }}.ve/-pre
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

os4d-makedocs:
  cmd.run:
    - name: . .ve/bin/activate; cd docs; make -e SPHINXOPTS="-D todo_include_todos=0" dirhtml
    - user: {{ user }}
    - cwd: {{ gitdir }}
    - require:
      - virtualenv: {{ gitdir }}.ve/
    - onchanges:
      - git: {{ giturl }}
