{% from 'lib.sls' import createuser, private_keys %}

{% set user = 'archive' %}
{{ createuser(user) }}
{{ private_keys(user) }}

/etc/sudoers.d/archive:
  file.managed:
    - source: salt://ocdskingfisherarchive/archive.sudoers
    - makedirs: True
