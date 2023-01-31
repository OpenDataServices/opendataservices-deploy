{% from 'lib.sls' import createuser, apache %}

include:
  - core
  - apache

{% set user = 'os4dstatic' %}
{{ createuser(user, world_readable_home_dir='yes') }}

/home/{{ user }}/web:
  git.latest:
    - name: https://github.com/OpenDataServices/os4d-static.git
    - rev: {{ pillar.os4d_static.branch }}
    - target: /home/{{ user }}/web
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git



# Set up the Apache config using macro
{{ apache('os4d-static.conf', servername=pillar.os4d_static.servername, https=pillar.os4d_static.https) }}

