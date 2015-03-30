{% set user = 'opendataservices' %}

{% from 'lib.sls' import createuser, apache %}

{{ createuser(user) }}

git:
  pkg.installed


{% for file in ['id_rsa', 'id_rsa.pub'] %}
/home/{{ user }}/.ssh/{{ file }}:
  file.managed:
    - source: salt://ssh/{{ file }}    
{% endfor %}

opendataservices.plan.io:
  ssh_known_hosts:
    - present
    - user: {{ user }}
    - enc: rsa
    - fingerprint: 77:d1:54:d7:33:7e:38:43:40:70:ca:2d:3a:24:05:22

git@opendataservices.plan.io:standardsupport-civic-data-standards.website.git:
  git.latest:
    - rev: live
    - target: /home/{{ user }}/website/
    - user: {{ user }}
    - submodules: True
    - require:
      - pkg: git


{{ apache('opendataservices-website.conf') }}

