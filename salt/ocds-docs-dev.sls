include:
  - apache-proxy

{% from 'lib.sls' import createuser, apache %}
{{ apache('ocds-docs-dev.conf') }}



{% set user = 'ocds-docs' %}
{{ createuser(user) }}

/home/{{ user }}/web/:
  file.directory:
    - user: {{ user }}
    - makedirs: True
    - mode: 755

{{ apache('ocds-docs.conf') }}
