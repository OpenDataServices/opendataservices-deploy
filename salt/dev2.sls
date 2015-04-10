include:
  - elasticsearch
  - kibana

/etc/elasticsearch/elasticsearch.yml:
  file.append:
    - text: |
        cluster.name: dev2
    - require:
      - pkg: elasticsearch-base

