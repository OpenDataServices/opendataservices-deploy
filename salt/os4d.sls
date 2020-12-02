{% from 'lib.sls' import createuser, apache, planio_keys %}

include:
  - core
  - apache
  - letsencrypt

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
{% set giturl = 'https://github.com/OpenDataServices/os4d.git' %}

{{ giturl }}:
  git.latest:
    - rev: live
    - target: {{ gitdir }}
    - user: {{ user }}
    - submodules: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

# Set up the Apache config using macro
{{ apache('os4d-handbook.conf', servername='os4d.opendataservices.coop', https=pillar.os4d_apache_https) }}

# Install pre requirements
{{ gitdir }}.ve/-pre:
  virtualenv.managed:
    - name: {{ gitdir }}.ve/
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ gitdir }}pre_requirements.txt
    - require:
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
