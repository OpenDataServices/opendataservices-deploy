icinga2:
  pkgrepo.managed:
    - ppa: formorer/icinga
    - require_in:
      pkg: icinga2
  pkg.installed:
    - pkgs:
      - icinga2
      - nagios-plugins
    - refresh: True
    - require:
      - pkgrepo: icinga2
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - pkg: icinga2

{% for confname in ['apt'] %}
/etc/icinga2/conf.d/{{ confname }}.conf:
  file.managed:
    - source: salt://icinga/{{ confname }}.conf
    - watch_in:
      - service: icinga2
{% endfor %}
