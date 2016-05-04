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


# Macro for grantnav uswgi and apache configs
# Having this seperate to grantnav_files is useful to have different indexes
# for the same code files on disk
{% macro grantnav_uwsgi_apache(name, djangodir, user, uwsgi_port, index_suffix='') %}

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

{% endmacro %}


# Macro for grantnav code files on disk
{% macro grantnav_files(giturl, branch, djangodir, user) %}

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

collectstatic-{{djangodir}}:
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
      - cmd: collectstatic-{{djangodir}}

{{ djangodir }}:
  file.directory:
    - dir_mode: 755
    - require:
      - cmd: collectstatic-{{djangodir}}

{% endmacro %}

# Main copy of grantnav at http://grantnav.grantnav-dev.default.opendataservices.uk0.bigv.io/
{{ grantnav_uwsgi_apache(
    name='grantnav',
    djangodir='/home/'+user+'/grantnav/',
    uwsgi_port=3031,
    user=user) }}
{{ grantnav_files(
    giturl=giturl,
    branch='iteration03',
    djangodir='/home/'+user+'/grantnav/',
    user=user) }}

# Extra copies of grantnav for specific branches and/or index suffix
# 
# If you cause a new uwsgi port to be used, uwsgi will need restarting manually
# (See also dev_pillar.sls for the Cove equivalent).
{% for branch, index_suffix, create_files in [
  ('master', 'dev', True),
  ('master', 'big', False),
  ('iteration03-before-theming', 'notheme', True),
  ] %}
{% if branch %}
  {% set djangodir='/home/'+user+'/grantnav-'+branch+'/' %}
{% else %}
  {% set djangodir='/home/'+user+'/grantnav/' %}
{% endif %}
{{ grantnav_uwsgi_apache(
    name='grantnav-'+index_suffix,
    index_suffix=index_suffix,
    djangodir=djangodir,
    uwsgi_port=3031+loop.index,
    user=user) }}
{% if branch and create_files %}
{{ grantnav_files(
    giturl=giturl,
    branch=branch,
    djangodir=djangodir,
    user=user) }}
{% endif %}
{% endfor %}

{% for subdomain, htpasswd in pillar.htpasswd_by_subdomain.items() %}
/etc/apache2/htpasswd-{{ subdomain }}:
  file.managed:
    - contents_pillar: htpasswd_by_subdomain:{{ subdomain }}
    - makedirs: True
{% endfor %}

/root/reload_data.sh:
  file.managed:
    - contents:
      - '#!/bin/bash'
      - set -i
      - su grantnav -c /home/grantnav/reload_data.sh
    - mode: 755

/home/grantnav/reload_data.sh:
  file.managed:
    - source: salt://grantnav/reload_data.sh
    - mode: 755
