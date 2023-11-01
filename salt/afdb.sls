{% from 'lib.sls' import createuser %}

include:
  - core

##################################################################### Normal User

{% set user = 'afdb' %}
{{ createuser(user) }}

##################################################################### Add to docker group

docker:
  group:
    - present

usermod -a -G docker afdb:
  cmd.run:
    - require:
      - group: docker
