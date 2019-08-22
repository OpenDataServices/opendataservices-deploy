
{% from 'lib.sls' import createuser, apache %}

include:
  - apache
  - apache-proxy

prometheus-client-deps:
    pkg.installed:
      - pkgs:
        - curl

{% set user = 'prometheus-client' %}
{{ createuser(user) }}

########### Get binary

get_prometheus_client:
  cmd.run:
    - name: curl -L https://github.com/prometheus/node_exporter/releases/download/v{{ pillar.prometheus.node_exporter_version }}/node_exporter-{{ pillar.prometheus.node_exporter_version }}.linux-amd64.tar.gz -o /home/{{ user }}/node_exporter-{{ pillar.prometheus.node_exporter_version }}.tar.gz
    - creates: /home/{{ user }}/node_exporter-{{ pillar.prometheus.node_exporter_version }}.tar.gz
    - requires:
      - pkg.prometheus-client-deps
      - user: {{ user }}_user_exists

extract_prometheus_client:
  cmd.run:
    - name: tar xvzf node_exporter-{{ pillar.prometheus.node_exporter_version }}.tar.gz
    - creates: /home/{{ user }}/node_exporter-{{ pillar.prometheus.node_exporter_version }}.linux-amd64/node_exporter
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_prometheus

########### Service

/etc/systemd/system/prometheus-node-exporter.service:
  file.managed:
    - source: salt://prometheus-client/prometheus-node-exporter.service
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

prometheus-node-exporter:
  service.running:
    - enable: True
    - requires:
      - file: /etc/systemd/system/prometheus-node-exporter.service
      - cmd: extract_prometheus_client
    # Make sure service restarts if any config changes
    - watch:
      - file: /etc/systemd/system/prometheus-node-exporter.service

########### Apache Reverse Proxy with password for security

{% set extracontext %}
user: {{ user }}
{% endset %}

{{ apache('prometheus-client.conf',
    name='prometheus-client.conf',
    extracontext=extracontext,
    servername=pillar.prometheus.client_fqdn if pillar.prometheus.client_fqdn else 'prom-client.'+grains.fqdn ) }}

prometheus-client-apache-password:
  cmd.run:
    - name: rm /home/{{ user }}/htpasswd ; htpasswd -c -b /home/{{ user }}/htpasswd prom {{ pillar.prometheus.client_password }}
    - runas: {{ user }}
    - cwd: /home/{{ user }}



