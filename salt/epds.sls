# EPDS (Environmental Permit Data Service)
#
# Ubuntu 20 LTS only!
#


{% from 'lib.sls' import createuser, apache, uwsgi, removeapache, removeuwsgi %}

{% set user = 'epds' %}
{{ createuser(user) }}

include:
  - core
  - apache
  - uwsgi
  - letsencrypt


epds-deps:
    apache_module.enabled:
      - name: proxy proxy_uwsgi
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python3-pip
        - python3-virtualenv
        - uwsgi-plugin-python3
        - libpq-dev
        - gcc
        - make
        - python3-dev
      - watch_in:
        - service: apache2
        - service: uwsgi
