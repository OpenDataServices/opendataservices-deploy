
{% from 'lib.sls' import createuser, apache %}


prometheus-blackbox-deps:
    pkg.installed:
      - pkgs:
        - curl

{% set user = 'prometheus-blackbox' %}
{{ createuser(user) }}

########### Get binary

get_prometheus_blackbox:
  cmd.run:
    - name: curl -L https://github.com/prometheus/blackbox_exporter/releases/download/v{{ pillar.prometheus.server_blackbox_exporter_version }}/blackbox_exporter-{{ pillar.prometheus.server_blackbox_exporter_version }}.linux-amd64.tar.gz -o /home/{{ user }}/blackbox_exporter-{{ pillar.prometheus.server_blackbox_exporter_version }}.tar.gz
    - creates: /home/{{ user }}/blackbox_exporter-{{ pillar.prometheus.server_blackbox_exporter_version }}.tar.gz
    - requires:
      - pkg.prometheus-server-deps
      - user: {{ user }}_user_exists

extract_prometheus_blackbox:
  cmd.run:
    - name: tar xvzf blackbox_exporter-{{ pillar.prometheus.server_blackbox_exporter_version }}.tar.gz
    - creates: /home/{{ user }}/blackbox_exporter-{{ pillar.prometheus.server_blackbox_exporter_version }}.linux-amd64/blackbox_exporter
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_prometheus_blackbox

########### Config


/home/{{ user }}/conf-blackbox.yml:
  file.managed:
    - source: salt://private/prometheus-server-blackbox/conf-blackbox.yml
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

########### Service

/etc/systemd/system/prometheus-blackbox.service:
  file.managed:
    - source: salt://prometheus-server-blackbox/prometheus-blackbox.service
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

prometheus-blackbox:
  service.running:
    - enable: True
    - requires:
      - cmd: extract_prometheus_blackbox
    # Make sure service restarts if any config changes
    - watch:
      - file: /home/{{ user }}/conf-blackbox.yml
      - file: /etc/systemd/system/prometheus-blackbox.service

