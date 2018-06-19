icinga2:
  {% if grains['osrelease'] != '18.04' %}
  pkgrepo.managed:
    - ppa: formorer/icinga
    - require_in:
      pkg: icinga2
  {% endif %}
  pkg.installed:
    - pkgs:
      - icinga2
      - nagios-plugins
      - nagios-plugins-contrib
    - refresh: True
  {% if grains['osrelease'] != '18.04' %}
    - require:
      - pkgrepo: icinga2
  {% endif %}
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - pkg: icinga2

{% for confname in ['apt', 'services'] %}
/etc/icinga2/conf.d/{{ confname }}.conf:
  file.managed:
    - source: salt://icinga/{{ confname }}.conf
    - watch_in:
      - service: icinga2
    - template: jinja
{% endfor %}

{% for confname in ['icinga2'] %}
/etc/icinga2/{{ confname }}.conf:
  file.managed:
    - source: salt://icinga/{{ confname }}.conf
    - watch_in:
      - service: icinga2
{% endfor %}

# bugfix: planio#5476
{% if grains['osrelease'] == '16.04' %}
/usr/lib/nagios/plugins/check_memory:
  file.patch:
    - source: salt://icinga/check_memory_new_free_output.patch
    - hash: md5=d7f464052b3114f90948c0488df30b25
{% endif %}

{% if grains['osrelease'] == '18.04' %}
/etc/icinga2/repository.d/:
  file.directory:
    - makedirs: True
{% endif %}
