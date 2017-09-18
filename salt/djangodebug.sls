{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'djangodebug' %}
{{ createuser(user) }}

apache_mods:
    apache_module.enabled:
      - name: proxy
      - watch_in:
        - service: apache2

python3-dev:
  pkg.installed

{{ apache(user+'.conf') }}
