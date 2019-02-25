{% from 'lib.sls' import createuser, private_keys %}

{% set user = 'archive' %}
{{ createuser(user) }}
{{ private_keys(user) }}

{% set userdir = '/home/' + user %}

/etc/sudoers.d/archive:
  file.managed:
    - source: salt://ocdskingfisherarchive/archive.sudoers
    - makedirs: True

{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/ocdskingfisher_archive_.pgpass
    - template: jinja
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0400
