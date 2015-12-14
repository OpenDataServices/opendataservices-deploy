include:
  - elasticsearch
  - kibana
  # Install apache to provide authentication in front of elasticsearch and
  # kibana. Nginx would probably be a better fit for this, but we currently
  # don't use it anywhere else, so I'm sticking with Apache for increased
  # consistency across our servers.
  - apache-proxy

/etc/elasticsearch/elasticsearch.yml:
  file.append:
    - text: |
        cluster.name: dev2
    - require:
      - pkg: elasticsearch-base

{% from 'lib.sls' import createuser, apache %}
{{ apache('dev2.conf') }}



{% set user = 'tmp-prototype-ocds-docs' %}
{{ createuser(user) }}

/home/{{ user }}/web/:
  file.directory:
    - user: {{ user }}
    - makedirs: True
    - mode: 755

{{ apache('tmp-prototype-ocds-docs.conf') }}
