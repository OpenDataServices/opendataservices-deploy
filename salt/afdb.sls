{% from 'lib.sls' import createuser %}

include:
  - core

##################################################################### Normal User

{% set user = 'afdb' %}
{{ createuser(user) }}
