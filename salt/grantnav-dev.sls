{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'grantnav' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/OpenDataServices/grantnav.git' %}

include:
  - core
  - elasticsearch
  - kibana
  # Install apache to provide authentication in front of elasticsearch and
  # kibana. Nginx would probably be a better fit for this, but we currently
  # don't use it anywhere else, so I'm sticking with Apache for increased
  # consistency across our servers.
  - apache-proxy

/etc/elasticsearch/elasticsearch.yml:
  file.append:
    - text: |
        cluster.name: grantnav-dev
    - require:
      - pkg: elasticsearch-base

uwsgi:
  # Ensure that uwsgi is installed
  pkg:
    - installed
  # Ensure uwsgi running, and reload if any of the conf files change
  service:
    - running
    - enable: True
    - reload: True

unzip:
  pkg:
    - installed

grantnav-deps:
    apache_module.enable:
      - name: proxy
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
        - gettext
      - watch_in:
        - service: apache2
        - service: uwsgi

set_lc_all:
  file.append:
    - text: 'LC_ALL="en_GB.UTF-8"'
    - name: /etc/default/locale


{% macro grantnav(name, giturl, branch, djangodir, user, uwsgi_port, index_suffix='') %}

{% set apache_extracontext %}
djangodir: {{ djangodir }}
uwsgi_port: {{ uwsgi_port }}
subdomain: {{ name }}
{% endset %}

{{ apache(user+'.conf',
    name=name+'.conf',
    extracontext=apache_extracontext) }}

{% set uwsgi_extracontext %}
es_index: threesixtygiving{% if index_suffix %}_{{ index_suffix }}{% endif %}
{% endset %}

{{ uwsgi(user+'.ini',
    name=name+'.ini',
    djangodir=djangodir,
    port=uwsgi_port,
    extracontext=uwsgi_extracontext) }}

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
    - requirements: {{ djangodir }}requirements.txt
    - require:
      - pkg: grantnav-deps
      - git: {{ giturl }}{{ djangodir }}
      - file: set_lc_all # required to avoid unicode errors for the "schema" library
    - watch_in:
      - service: apache2

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

{{ djangodir }}:
  file.directory:
    - dir_mode: 755
    - require:
      - cmd: collectstatic-{{name}}

{% endmacro %}

{{ grantnav(
    name='grantnav',
    giturl=giturl,
    branch=pillar.default_branch,
    djangodir='/home/'+user+'/grantnav/',
    uwsgi_port=3031,
    user=user) }}

# If you cause a new uwsgi port to be used, uwsgi will need restarting manually
# (See also dev_pillar.sls for the Cove equivalent).
{% for index_suffix in [ 'validdata' ] %}
{{ grantnav(
    name='grantnav-'+index_suffix,
    index_suffix=index_suffix,
    giturl=giturl,
    branch=pillar.default_branch,
    djangodir='/home/'+user+'/grantnav-'+index_suffix+'/',
    uwsgi_port=3031+loop.index,
    user=user) }}
{% endfor %}
