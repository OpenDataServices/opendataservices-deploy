# Salt formula for setting up server log analytics:
# for this we use the common combination of logstash, elasticsearch and kibana
# (sometimes called the ELK stack)
include:
  - elasticsearch
  - kibana

logserver-base:
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

#cluster.name: elasticsearch
