include:
  - apache-proxy

{% from 'lib.sls' import createuser, apache %}
{{ apache('dev3.conf') }}



{% set user = 'ocds-docs' %}
{{ createuser(user) }}

/home/{{ user }}/web/:
  file.directory:
    - user: {{ user }}
    - makedirs: True
    - mode: 755

{{ apache('ocds-docs.conf') }}
