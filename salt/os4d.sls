{% from 'lib.sls' import createuser, apache, planio_keys %}

include:
  - core
  - apache
  - letsencrypt

os4d-deps:
    pkg.installed:
      - pkgs:
{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
        - python-pip
        - python-virtualenv
{% endif %}
{% if grains['osrelease'] == '20.04' %}
        - python3-pip
        - python3-virtualenv
{% endif %}
        - graphviz

{% set user = 'os4d' %}
{{ createuser(user) }}
{{ planio_keys(user) }}

{% set gitdir = '/home/' + user + '/handbook/' %}
{% set giturl = 'https://github.com/OpenDataServices/os4d.git' %}

{{ giturl }}:
  git.latest:
{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
    - rev: live
{% endif %}
{% if grains['osrelease'] == '20.04' %}
# This is https://github.com/OpenDataServices/os4d/pull/6 - once that is merged to live this can be removed!
    - rev: update
{% endif %}
    - target: {{ gitdir }}
    - user: {{ user }}
    - submodules: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

# Set up the Apache config using macro
{{ apache('os4d-handbook.conf', servername='os4d.opendataservices.coop', https=pillar.os4d_apache_https) }}


{% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}

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

{% endif %}
{% if grains['osrelease'] == '20.04' %}

{{ gitdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    # see below: - requirements: {{ gitdir }}requirements.txt
    - require:
      - git: {{ giturl }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

# THIS SHOULD IDEALLY BE IN virtualenv.managed BUT WE GET A PERMISSION ERROR IF WE DO THAT
install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user }}
    - cwd: {{ gitdir }}
    - require:
      - virtualenv: {{ gitdir }}.ve/
    - onchanges:
      - git: {{ giturl }}

os4d-makedocs:
  cmd.run:
    - name: . .ve/bin/activate; cd docs; make -e SPHINXOPTS="-D todo_include_todos=0" dirhtml
    - user: {{ user }}
    - cwd: {{ gitdir }}
    - require:
      - cmd: install-python-packages
    - onchanges:
      - git: {{ giturl }}

{% endif %}
