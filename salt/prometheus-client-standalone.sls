#
# Sets up Prometheus Client on a server as standalone service
# Does not interfere with anything else running on port 80 or 443
#

{% from 'lib.sls' import createuser %}



prometheus-client-deps:
    pkg.installed:
      - pkgs:
        - curl

{% set user = 'prometheus-client' %}
{{ createuser(user, world_readable_home_dir='yes') }}

########### Textfile collector location
/home/{{ user }}/textfile_directory:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 777
    - requires:
      - user: {{ user }}_user_exists

########### Get binary

get_prometheus_client:
  cmd.run:
    - name: curl -L https://github.com/prometheus/node_exporter/releases/download/v{{ pillar.prometheus.node_exporter_version_for_standalone }}/node_exporter-{{ pillar.prometheus.node_exporter_version_for_standalone }}.linux-amd64.tar.gz -o /home/{{ user }}/node_exporter-{{ pillar.prometheus.node_exporter_version_for_standalone }}.tar.gz
    - creates: /home/{{ user }}/node_exporter-{{ pillar.prometheus.node_exporter_version_for_standalone }}.tar.gz
    - requires:
      - pkg.prometheus-client-deps
      - user: {{ user }}_user_exists

extract_prometheus_client:
  cmd.run:
    - name: tar xvzf node_exporter-{{ pillar.prometheus.node_exporter_version_for_standalone }}.tar.gz
    - creates: /home/{{ user }}/node_exporter-{{ pillar.prometheus.node_exporter_version_for_standalone }}.linux-amd64/node_exporter
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_prometheus

########### Service

/home/{{ user }}/web-config.yaml:
  file.managed:
    - source: salt://prometheus-client/web-config-for-standalone.yaml
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

/etc/systemd/system/prometheus-node-exporter.service:
  file.managed:
    - source: salt://prometheus-client/prometheus-node-exporter-for-standalone.service
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
      - file: /home/{{ user }}/web-config.yaml
      - cmd: extract_prometheus_client
    # Make sure service restarts if any config changes
    - watch:
      - file: /etc/systemd/system/prometheus-node-exporter.service
