include:
  - elasticsearch
  - kibana
  # Install apache to provide authentication in front of elasticsearch and
  # kibana. Nginx would probably be a better fit for this, but we currently
  # don't use it anywhere else, so I'm sticking with Apache for increased
  # consistency across our servers.
  - apache

/etc/elasticsearch/elasticsearch.yml:
  file.append:
    - text: |
        cluster.name: dev2
    - require:
      - pkg: elasticsearch-base

{% from 'lib.sls' import apache %}
{{ apache('dev2.conf') }}

proxy:
    apache_module.enable
proxy_http:
    apache_module.enable
