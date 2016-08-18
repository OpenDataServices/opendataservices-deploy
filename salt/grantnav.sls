# To reload this from scratch, do
# rm -r /etc/apache2/sites-*/* /etc/uwsgi/apps-*/ /home/grantnav/grantnav* /tmp/*.sock /etc/apache2/htpasswd*
# and then run highstate.

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
        cluster.name: {{ grains.host }}
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

# Currently we require apache from trusty backports
# (This is because we now use unix sockets instead of port numbers to
# communicate between apache and uwsgi).
grantnav-backports-deps:
    pkg.installed:
      - fromrepo: trusty-backports
      - pkgs:
        - apache2
        - apache2-bin
        - apache2-data

set_lc_all:
  file.append:
    - text: 'LC_ALL="en_GB.UTF-8"'
    - name: /etc/default/locale




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


# Deploy multiple copies of grantnav for specific branches and/or index suffix
# 
# If you cause a new uwsgi port to be used, uwsgi will need restarting manually
# (See also dev_pillar.sls for the Cove equivalent).

{% if pillar.grantnav.deploy_mode == 'matrix' %}



{% for branch in pillar.grantnav.branches %}
{% set djangodir='/home/'+user+'/grantnav-'+branch+'/' %}
{{ grantnav_files(
    giturl=giturl,
    branch=branch,
    djangodir=djangodir,
    user=user) }}

{% for deploy, deploy_info in pillar.grantnav.deploys.items() %}
{% for dataselection in pillar.grantnav.dataselections %}
{% set deployment_base_name = 'grantnav_' + dataselection + '_' + branch %}
{% set es_index = deployment_base_name + '_' + deploy_info.datadate %}
{% set deployment_name = deployment_base_name + '_' + deploy %}
{% set apache_extracontext %}
djangodir: '{{ djangodir }}'
subdomain: '{{ deploy }}.{{ dataselection }}.{{ branch }}'
{% endset %}

{{ apache(user+'.conf',
    name=deployment_name+'.conf',
    socket_name=deployment_name,
    extracontext=apache_extracontext) }}

{% set uwsgi_extracontext %}
es_index: '{{ es_index }}'
dataselection: '{{ dataselection }}'
datadate: '{{ deploy_info.datadate }}'
{% endset %}

{{ uwsgi(user+'.ini',
    name=deployment_name+'.ini',
    socket_name=deployment_name,
    djangodir=djangodir,
    extracontext=uwsgi_extracontext) }}
{% endfor %}
{% endfor %}
{% endfor %}



{% else %}




{% endif %}

#{% for subdomain, htpasswd in pillar.htpasswd_by_subdomain.items() %}
#/etc/apache2/htpasswd-{{ subdomain }}:
#  file.managed:
#    - contents_pillar: htpasswd_by_subdomain:{{ subdomain }}
#    - makedirs: True
#{% endfor %}

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
    - template: jinja
    - mode: 755

{{ apache('grantnav_default.conf',
    name='000-default.conf') }}

{{ apache('grantnav_list.conf') }}

/home/grantnav/list/index.html:
  file.managed:
    - source: salt://grantnav/list.html
    - template: jinja
    - makedirs: True
