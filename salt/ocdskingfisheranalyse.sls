{% from 'lib.sls' import createuser %}

# Set up the things people need to be able to make use of the powerful server for analysis work

ocdskingfisheranalyse-prerequisites  :
  pkg.installed:
    - pkgs:
      - unrar

{% set user = 'analysis' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/open-contracting/kingfisher.git' %}
{% set userdir = '/home/' + user %}
{% set flattentooldir = userdir + '/flatten-tool/' %}

{{ giturl }}{{ flattentooldir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - branch: archive
    - rev: archive
    - target: {{ flattentooldir }}
    - require:
      - pkg: git

{{ flattentooldir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ flattentooldir }}
    - requirements: {{ flattentooldir }}requirements.txt
    - require:
      - git: {{ giturl }}{{ flattentooldir }}


