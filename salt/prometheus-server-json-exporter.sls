
{% from 'lib.sls' import createuser, apache %}


prometheus-json-exporter-deps:
    pkg.installed:
      - pkgs:
        - curl

{% set user = 'prometheus-json-exporter' %}
{{ createuser(user) }}

########### Get binary

get_prometheus_json_exporter:
  cmd.run:
    - name: curl -L https://github.com/prometheus-community/json_exporter/releases/download/v{{ pillar.prometheus.server_json_exporter_version }}/json_exporter-{{ pillar.prometheus.server_json_exporter_version }}.linux-amd64.tar.gz -o /home/{{ user }}/json_exporter-{{ pillar.prometheus.server_json_exporter_version }}.tar.gz
    - creates: /home/{{ user }}/json_exporter-{{ pillar.prometheus.server_json_exporter_version }}.tar.gz
    - requires:
      - pkg.prometheus-server-deps
      - user: {{ user }}_user_exists

extract_prometheus_json_exporter:
  cmd.run:
    - name: tar xvzf json_exporter-{{ pillar.prometheus.server_json_exporter_version }}.tar.gz
    - creates: /home/{{ user }}/json_exporter-{{ pillar.prometheus.server_json_exporter_version }}.linux-amd64/json_exporter
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_prometheus_json_exporter

########### Config


/home/{{ user }}/conf-json-exporter.yml:
  file.managed:
    - source: salt://private/prometheus-server-json-exporter/conf-json-exporter.yml
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

########### Service

/etc/systemd/system/prometheus-json-exporter.service:
  file.managed:
    - source: salt://prometheus-server-json-exporter/prometheus-json-exporter.service
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

prometheus-json-exporter:
  service.running:
    - enable: True
    - requires:
      - cmd: extract_prometheus_json_exporter
    # Make sure service restarts if any config changes
    - watch:
      - file: /home/{{ user }}/conf-json-exporter.yml
      - file: /etc/systemd/system/prometheus-json-exporter.service

