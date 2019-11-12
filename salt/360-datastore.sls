
{% from 'lib.sls' import createuser, apache, uwsgi  %}

include:
  - apache
  - uwsgi

360-datastore-packages:
  pkg.installed:
    - pkgs:
      - postgresql-10
      - postgresql-server-dev-10

{% set user = 'datastore' %}
{{ createuser(user) }}


{% macro threesixtygiving_datastore(datastore_branch, datatester_branch) %}

##### Git checkout

/home/{{ user }}/datastore:
  git.latest:
    - name: https://github.com/threesixtygiving/datastore.git
    - rev: {{ datastore_branch }}
    - target: /home/{{ user }}/datastore
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

/home/{{ user }}/datatester:
  git.latest:
    - name: https://github.com/ThreeSixtyGiving/datatester.git
    - rev: {{ datatester_branch }}
    - target: /home/{{ user }}/datatester
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

###### Virtual Envs

/home/{{ user }}/datastore/.ve:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: /home/{{ user }}/datastore/requirements.txt
    - require:
      - git: /home/{{ user }}/datastore

/home/{{ user }}/datatester/.ve:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: /home/{{ user }}/datatester/requirements.txt
    - require:
      - git: /home/{{ user }}/datatester

{{ apache('360-datastore.conf',
    name='360-datastore.conf',
    servername='datastore-dev.grantnav.threesixtygiving.org',
    serveraliases=[],
    https='no'
    ) }}

{{ uwsgi('360-datastore.ini',
    name='360-datastore.ini'
    ) }}

{% endmacro %}


{{ threesixtygiving_datastore(
        datastore_branch='master',
        datatester_branch='master'
    ) }}

