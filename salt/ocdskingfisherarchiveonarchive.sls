{% from 'lib.sls' import createuser %}


{% set user = 'archive' %}
{{ createuser(user) }}
{% set userdir = '/home/' + user %}

{{ userdir }}/data:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}

