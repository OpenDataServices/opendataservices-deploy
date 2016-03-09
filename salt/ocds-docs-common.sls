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

/home/ocds-docs/web/includes/:
  file.recurse:
    - source: salt://ocds-docs/includes
    - user: ocds-docs

mod_include:
  apache_module.enable:
    - name: include

rewrite:
  apache_module.enable

