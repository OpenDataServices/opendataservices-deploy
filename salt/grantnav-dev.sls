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
        cluster.name: grantnav-dev
    - require:
      - pkg: elasticsearch-base

{% from 'lib.sls' import createuser, apache %}
{{ apache('grantnav-dev.conf') }}

