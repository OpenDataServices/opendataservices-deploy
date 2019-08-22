
{% from 'lib.sls' import createuser, apache %}

include:
  - prometheus-server-server
  - prometheus-server-alertmanager
