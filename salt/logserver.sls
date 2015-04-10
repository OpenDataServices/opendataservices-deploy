# Salt formula for setting up server log analytics:
# for this we use the common combination of logstash, elasticsearch and kibana
# (sometimes called the ELK stack)
logserver-base:
  cmd.run:
    - name: wget -O - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

  pkgrepo.managed:
    - humanname: Logstash
    - name: deb http://packages.elasticsearch.org/logstash/1.4/debian stable main
    - file: /etc/apt/sources.list.d/logstash.list

  pkg.installed:
    - pkgs:
      - logstash
      - logstash-contrib

  service.running:
    - name: logstash
    - enable: True

elasticsearch-base:
  pkgrepo.managed:
    - humanname: Elasticsearch
    - name: deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main
    - file: /etc/apt/sources.list.d/elasticsearch.list

  pkg.installed:
    - pkgs:
      - elasticsearch

  service.running:
    - name: elasticsearch
    - enable: True
    - watch:
      - file: /etc/elasticsearch/*

kibana-base:
  archive.extracted:
    - name: /opt/
    - source: https://download.elastic.co/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz
    - source_hash: sha1=c925f75cd5799bfd892c7ea9c5936be10a20b119
    - archive_format: tar
    - if_missing: /opt/kibana-4.0.2-linux-x64/

  file.append:
    - name: /etc/elasticsearch/elasticsearch.yml
    - text: |
        http.cors.enabled: true
