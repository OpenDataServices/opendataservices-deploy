{% macro createuser(user) %}

{{ user }}-user-exists:
  user.present:
    - name: {{ user }}
    - home: /home/{{ user }}

{% endmacro %}


{% macro apache(conffile) %}

/etc/apache2/sites-available/{{ conffile }}:
  file.managed:
    - source: salt://apache/{{ conffile }}
    - template: jinja

/etc/apache2/sites-enabled/{{ conffile }}:
    file.symlink:
        - target: /etc/apache2/sites-available/{{ conffile }}

apache2:
  pkg.installed:
    -
  service:
    - running
    - enable: True
    - reload: True
    - watch:
      - file: /etc/apache2/sites-available/{{ conffile}}

{% endmacro %}
