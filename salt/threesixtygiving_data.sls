{% from 'lib.sls' import apache, createuser, planio_keys %}
{{ apache('threesixtygiving_data.conf') }}

{% set user = 'threesixtygiving_data' %}
{{ createuser(user) }}
{{ planio_keys(user) }}

git@opendataservices.plan.io:standardsupport-registry.data_threesixtygiving_org.git:
  git.latest:
    - force_fetch: True
    - force_reset: True
    - rev: master
    - target: /home/{{ user }}/web/
    - user: {{ user }}
    - require:
      - pkg: git
      - ssh_known_hosts: {{ user }}-opendataservices.plan.io
