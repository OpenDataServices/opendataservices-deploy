{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'standard-search' %}
{% set name = 'ocds-search' %}

{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/standard-search.git' %}

include:
  - core
  - apache
  - uwsgi
  - letsencrypt

standard-search-deps:
    apache_module.enabled:
      - name: proxy
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
        - apt-transport-https
      - watch_in:
        - service: apache2
        - service: uwsgi

standard-search-uwsgi:
    apache_module.enabled:
      - name: proxy_uwsgi
      - watch_in:
        - service: apache2
      - require:
        - pkg: standard-search-deps


elasticsearch:
  cmd.run:
    - name: wget -O - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

  pkgrepo.managed:
    - humanname: Elasticsearch
    - name: deb https://artifacts.elastic.co/packages/6.x/apt stable main
    - file: /etc/apt/sources.list.d/elasticsearch.list

  pkg.installed:
    - pkgs:
      - elasticsearch
      - openjdk-8-jre-headless

  service.running:
    - name: elasticsearch
    - enable: True
    - watch:
      - file: /etc/elasticsearch/*

  # Ensure elasticsearch only listens on localhost, doesn't multicast
  file.append:
    - name: /etc/elasticsearch/elasticsearch.yml
    - text: |
        network.host: 127.0.0.1

/etc/default/elasticsearch:
  file.managed:
    - source: salt://etc-default/elasticsearch-standard-search
    - template: jinja

/etc/elasticsearch/jvm.options:
  file.managed:
    - source: salt://standard-search/jvm.options
    - template: jinja


{% macro standard_search(name, branch, giturl, user, servername, https, serveraliases=[]) %}

{% set djangodir='/home/'+user+'/'+name+'/' %}

{% set extracontext %}
djangodir: {{ djangodir }}
branch: {{ branch }}
bare_name: {{ name }}
{% endset %}

{{ apache(user+'.conf',
    name=name+'.conf',
    https=https,
    servername=servername,
    serveraliases=serveraliases,
    extracontext=extracontext) }}

{{ uwsgi(user+'.ini',
    name=name+'.ini',
    extracontext=extracontext) }}

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

# Install the latest version of pip first
# This is necessary to download linux wheels, which avoids building C code
{{ djangodir }}.ve/-pip:
  virtualenv.managed:
    - name: {{ djangodir }}.ve/
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - pip_pkgs: pip==8.1.2
    - require:
      - standard-search-uwsgi
      - git: {{ giturl }}{{ djangodir }}

# Then install the rest of our requirements
{{ djangodir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - requirements: {{ djangodir }}requirements.txt
    - require:
      - virtualenv: {{ djangodir }}.ve/-pip
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

migrate-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

#compilemessages-{{name}}:
#  cmd.run:
#    - name: . .ve/bin/activate; python manage.py compilemessages
#    - user: {{ user }}
#    - cwd: {{ djangodir }}
#    - require:
#      - virtualenv: {{ djangodir }}.ve/
#    - onchanges:
#      - git: {{ giturl }}{{ djangodir }}

collectstatic-{{name}}:
  cmd.run:
    - name: . .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}.ve/
    - onchanges:
      - git: {{ giturl }}{{ djangodir }}

{{ djangodir }}static/:
  file.directory:
    - file_mode: 644
    - dir_mode: 755
    - recurse:
      - mode
    - require:
      - cmd: collectstatic-{{name}}
    - user: {{ user }}
    - group: {{ user }}

{{ djangodir }}:
  file.directory:
    - dir_mode: 755
    - require:
      - cmd: collectstatic-{{name}}
    - user: {{ user }}
    - group: {{ user }}

{% endmacro %}


{{ standard_search(
    name='ocds-search',
    branch='master',
    giturl=giturl,
    user=user,
    servername='standard-search.open-contracting.org',
    serveraliases=['www.live.standard-search.opencontracting.uk0.bigv.io'],
    https='yes'
) }}

