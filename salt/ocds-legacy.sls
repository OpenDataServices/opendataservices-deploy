# This file sets up some redirects and an archived opendatacomparison static
# site for ocds.open-contracting.org, which has now been replaced by
# standard.open-contracting.org
#
{% from 'lib.sls' import createuser, apache %}


{% set user = 'opencontracting' %}
{{ createuser(user) }}

{% set repo = 'opendatacomparison-archive' %}
{% set giturl = 'https://github.com/OpenDataServices/'+repo~'.git' %}
{{ giturl }}:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - target: /home/{{ user }}/{{ repo }}/
    - user: {{ user }}
    - require:
      - pkg: git
    - watch_in:
      - service: apache2

{{ apache('ocds-legacy.conf') }}
