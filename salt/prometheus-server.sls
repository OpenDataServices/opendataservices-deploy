
{% from 'lib.sls' import createuser, apache %}

include:
  - prometheus-server-server
  - prometheus-server-alertmanager
  - prometheus-server-blackbox
  - prometheus-server-json-exporter

