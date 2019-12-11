
{% from 'lib.sls' import createuser, apache %}

include:
  - apache
  - apache-proxy
  - letsencrypt

prometheus-server-deps:
    pkg.installed:
      - pkgs:
        - curl

{% set user = 'prometheus-server' %}
{{ createuser(user) }}

########### Get binary

get_prometheus:
  cmd.run:
    - name: curl -L https://github.com/prometheus/prometheus/releases/download/v{{ pillar.prometheus.server_prometheus_version }}/prometheus-{{ pillar.prometheus.server_prometheus_version }}.linux-amd64.tar.gz -o /home/{{ user }}/prometheus-{{ pillar.prometheus.server_prometheus_version }}.tar.gz
    - creates: /home/{{ user }}/prometheus-{{ pillar.prometheus.server_prometheus_version }}.tar.gz
    - requires:
      - pkg.prometheus-server-deps
      - user: {{ user }}_user_exists

extract_prometheus:
  cmd.run:
    - name: tar xvzf prometheus-{{ pillar.prometheus.server_prometheus_version }}.tar.gz
    - creates: /home/{{ user }}/prometheus-{{ pillar.prometheus.server_prometheus_version }}.linux-amd64/prometheus
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_prometheus

########### Config

/home/{{ user }}/conf-prometheus.yml:
  file.managed:
    - source: salt://private/prometheus-server-server/conf-prometheus.yml
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

/home/{{ user }}/conf-prometheus-rules.yml:
  file.managed:
    - source: salt://private/prometheus-server-server/conf-prometheus-rules.yml
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

########### Data

/home/{{ user }}/data:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True
    - requires:
      - user: {{ user }}_user_exists

########### Service

/etc/systemd/system/prometheus-server.service:
  file.managed:
    - source: salt://prometheus-server-server/prometheus-server.service
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

prometheus-server:
  service.running:
    - enable: True
    - reload: True
    - requires:
      - cmd: extract_prometheus
      - file: /home/{{ user }}/data
    # Make sure service restarts if any config changes
    - watch:
      - file: /home/{{ user }}/conf-prometheus.yml
      - file: /home/{{ user }}/conf-prometheus-rules.yml
      - file: /etc/systemd/system/prometheus-server.service

########### Apache Reverse Proxy with password for security

{% set extracontext %}
user: {{ user }}
{% endset %}


{{ apache('prometheus-server.conf',
    name='prometheus-server.conf',
    extracontext=extracontext,
    servername=pillar.prometheus.server_fqdn,
    https=pillar.prometheus.server_https ) }}

prometheus-server-apache-password:
  cmd.run:
    - name: rm /home/{{ user }}/htpasswd ; htpasswd -c -b /home/{{ user }}/htpasswd prom {{ pillar.prometheus.server_password }}
    - runas: {{ user }}
    - cwd: /home/{{ user }}


