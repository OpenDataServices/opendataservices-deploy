{% from 'lib.sls' import createuser, apache %}

{% set user = 'coveodscoop' %}
{{ createuser(user) }}

/home/{{ user }}/web:
  git.latest:
    - name: https://github.com/OpenDataServices/cove-opendataservices-coop.git
    - rev: live
    - target: /home/{{ user }}/web
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

{% set extracontext %}
webdir: /home/{{ user }}/web
{% endset %}

# Set up the Apache config using macro
{{ apache(
'cove-opendataservices-coop.conf',
name='cove-opendataservices-coop.conf',
extracontext=extracontext,
) }}
