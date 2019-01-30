{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'sedldata' %}
{{ createuser(user) }}
# Set up the server
{% set giturl = 'https://github.com/OpenDataServices/sedldata.git' %}

include:
  - core
  - apache
  - uwsgi

sedldb-prerequisites :
  apache_module.enabled:
    - name: proxy proxy_uwsgi
    - watch_in:
      - service: apache2
  pkg.installed:
    - pkgs:
      - python-pip
      - python3-pip
      - python3-virtualenv
      - virtualenv
      - postgresql-10
      - tmux
      - sqlite3
      - strace
      - uwsgi-plugin-python3
      - libapache2-mod-proxy-uwsgi
    - watch_in:
      - service: apache2
      - service: uwsgi

proxy_http:
    apache_module.enabled:
      - watch_in:
        - service: apache2

remoteip:
    apache_module.enabled:
      - watch_in:
        - service: apache2

{% set userdir = '/home/' + user %}
{% set sedldatadir = userdir + '/sedldata/' %}

{{ giturl }}{{ sedldatadir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - rev: master
    - force_fetch: True
    - force_reset: True
    - target: {{ sedldatadir }}
    - require:
      - pkg: git

{{ sedldatadir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ sedldatadir }}
    - pip_pkgs: ["{{ sedldatadir }}"]
    - require:
      - git: {{ giturl }}{{ sedldatadir }}

  postgres_user.present:
    - name: sedldata
    - password: {{ pillar.get('sedl-db').postgres.sedldata.password }}

  postgres_database.present:
    - name: sedldata
    - owner: sedldata

{{ userdir }}/.pgpass:
  file.managed:
    - source: salt://postgres/sedl-db_.pgpass
    - template: jinja
    - user: sedldata
    - group: sedldata
    - mode: 0400

/etc/postgresql/10/main/pg_hba.conf:
  file.managed:
    - source: salt://postgres/sedl-db_pg_hba.conf

/etc/postgresql/10/main/postgresql.conf:
  file.managed:
    - source: salt://postgres/sedl-db_postgresql.conf

env_db_uri:
  environ.setenv:
    - name: DB_URI
    - value: postgresql://sedldata:{{ pillar.get('sedl-db').postgres.sedldata.password }}@localhost:5432/sedldata
    - update_minion: True


{% macro sedldash(name, giturl, branch, djangodir, user, uwsgi_port, servername=None, app='sedldash') %}


{% set extracontext %}
djangodir: {{ djangodir }}
{% if grains['osrelease'] == '16.04' %}{# or grains['osrelease'] == '18.04' %}#}
uwsgi_port: null
{% else %}
uwsgi_port: {{ uwsgi_port }}
{% endif %}
branch: {{ branch }}
app: {{ app }}
bare_name: {{ name }}
{% endset %}

{% if 'https' in pillar.sedldash
 %}
{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername if servername else branch+'.'+grains.fqdn,
    serveraliases=[ branch+'.'+grains.fqdn ] if servername else [],
    https=pillar.sedldash.https) }}
{% else %}
{{ apache(user+'.conf',
    name=name+'.conf',
    servername=servername if servername else 'default',
    extracontext=extracontext) }}
{% endif %}

{{ uwsgi(user+'.ini',
    name=name+'.ini',
    extracontext=extracontext,
    port=uwsgi_port) }}

{{ giturl }}{{ djangodir }}:
  git.latest:
    - name: {{ giturl }}
    - rev: {{ branch }}
    - target: {{ djangodir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
    - watch_in:
      - service: uwsgi

{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ djangodir }}requirements_dashboard.txt
    - require:
      - pkg: sedldb-prerequisites
      - git: {{ giturl }}{{ djangodir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2
{% endmacro %}


{{ sedldash(
    name='sedldash',
    giturl=giturl,
    branch='master',
    djangodir='/home/'+user+'/sedldash/',
    uwsgi_port=3032,
    servername=pillar.sedldash.servername if 'servername' in pillar.sedldash else None,
    app=pillar.sedldash.app if 'app' in pillar.sedldash else 'sedldash',
    user=user) }}

