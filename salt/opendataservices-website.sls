# This is a salt formula to set up the opendataservices website
# ie. http://opendataservices.coop

{% from 'lib.sls' import createuser, apache %}

include:
  - core

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'opendataservices' %}
{{ createuser(user) }}

# Add a public and private key to this server, so that it can authenticate
# against plan.io
{% for file in ['id_rsa', 'id_rsa.pub'] %}
/home/{{ user }}/.ssh/{{ file }}:
  file.managed:
    - contents_pillar: {{ file.replace('.', '_') }}
    - makedirs: True
{% endfor %}

# Ensure that we recognise the fingerprint of the plan.io git server
opendataservices.plan.io:
  ssh_known_hosts:
    - present
    - user: {{ user }}
    - enc: rsa
    - fingerprint: 77:d1:54:d7:33:7e:38:43:40:70:ca:2d:3a:24:05:22

# Download the repository (all static HTML)
git@opendataservices.plan.io:standardsupport-co-op.website.git:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: /home/{{ user }}/website/
    - user: {{ user }}
    - submodules: True
    - require:
      - pkg: git
      - ssh_known_hosts: opendataservices.plan.io

# Set up the Apache config using macro
{{ apache('opendataservices-website.conf') }}

