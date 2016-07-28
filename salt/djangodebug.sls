{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'djangodebug' %}
{{ createuser(user) }}

apache_mods:
    apache_module.enable:
      - name: proxy
      - watch_in:
        - service: apache2

{{ apache(user+'.conf') }}
