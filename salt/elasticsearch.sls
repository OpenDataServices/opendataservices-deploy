# Salt formula for setting up elasticsearch
elasticsearch-base:
  cmd.run:
    - name: wget -O - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

  pkgrepo.managed:
    - humanname: Elasticsearch
    - name: deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main
    - file: /etc/apt/sources.list.d/elasticsearch.list

  pkg.installed:
    - pkgs:
      - elasticsearch
      - openjdk-7-jre-headless

  service.running:
    - name: elasticsearch
    - enable: True
    - watch:
      - file: /etc/elasticsearch/*

  # Ensure elasticsearch only listens on localhost, doesn't multicast
  file.append:
    - name: /etc/elasticsearch/elasticsearch.yml
    - text: |
      network.host: 127.0.0.1
      discovery.zen.ping.multicast.enabled: false
