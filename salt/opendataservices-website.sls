# This is a salt formula to set up the opendataservices website
# ie. http://opendataservices.coop

{% from 'lib.sls' import createuser, apache, planio_keys %}

include:
  - core
  - apache
  - letsencrypt

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'opendataservices' %}
{{ createuser(user) }}
{{ planio_keys(user) }}

# Download the repository (all static HTML)
git@opendataservices.plan.io:standardsupport-co-op.website.git:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: /home/{{ user }}/website/
    - user: {{ user }}
    - submodules: False
    - force_reset: False
    - require:
      - pkg: git
      - ssh_known_hosts: {{ user }}-opendataservices.plan.io

# Set up the Apache config using macro
{% set servername = pillar.domain_prefix+'opendataservices.coop' %}
{{ apache('opendataservices-website.conf',
          servername = servername,
          serveraliases = [ 'www.'+servername ],
          https='yes') }}
