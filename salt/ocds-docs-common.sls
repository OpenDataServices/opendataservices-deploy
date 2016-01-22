include:
  - apache-proxy

{% from 'lib.sls' import createuser %}
{% set user = 'ocds-docs' %}
{{ createuser(user) }}

/home/{{ user }}/web/:
  file.directory:
    - user: {{ user }}
    - makedirs: True
    - mode: 755
