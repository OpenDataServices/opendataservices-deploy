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
  - uwsgi

/etc/elasticsearch/elasticsearch.yml:
  file.append:
    - text: |
        cluster.name: {{ grains.host }}
    - require:
      - pkg: elasticsearch-base

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
      - pkg: grantnav-deps
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
{% set extracontext %}
djangodir: '{{ djangodir }}'
es_index: '{{ es_index }}'
dataselection: '{{ dataselection }}'
datadate: '{{ deploy_info.datadate }}'
subdomain: '{{ deploy }}.{{ dataselection }}.{{ branch }}'
{% endset %}


{{ apache(user+'.conf',
    name=deployment_name+'.conf',
    socket_name=deployment_name,
    extracontext=extracontext) }}

{{ uwsgi(user+'.ini',
    name=deployment_name+'.ini',
    socket_name=deployment_name,
    extracontext=extracontext) }}
{% endfor %}
{% endfor %}
{% endfor %}



{{ apache('grantnav_list.conf') }}

/home/grantnav/list/index.html:
  file.managed:
    - source: salt://grantnav/list.html
    - template: jinja
    - makedirs: True


{% else %}


{% set branches = [] %}

{% for deploy, deploy_info in pillar.grantnav.deploys.items() %}
{% set branch = deploy_info.branch %}
{% set djangodir='/home/'+user+'/grantnav-'+branch+'/' %}

{% if not branch in branches %}
{% do branches.append(branch) %}
{% endif %}

{% set deployment_base_name = 'grantnav' %}
{% set es_index = deployment_base_name + '_' + deploy_info.datadate %}
{% set deployment_name = deployment_base_name + '_' + deploy %}
{% set apache_extracontext %}
djangodir: '{{ djangodir }}'
subdomain: '{{ deploy }}'
{% endset %}

{{ apache(user+'.conf',
    name=deployment_name+'.conf',
    socket_name=deployment_name,
    extracontext=apache_extracontext) }}

{% set uwsgi_extracontext %}
es_index: '{{ es_index }}'
dataselection: '{{ deploy_info.dataselection }}'
datadate: '{{ deploy_info.datadate }}'
subdomain: '{{ deploy }}'
{% endset %}

{{ uwsgi(user+'.ini',
    name=deployment_name+'.ini',
    socket_name=deployment_name,
    djangodir=djangodir,
    extracontext=uwsgi_extracontext) }}
{% endfor %}

{% for branch in branches %}
{% set djangodir='/home/'+user+'/grantnav-'+branch+'/' %}
{{ grantnav_files(
    giturl=giturl,
    branch=branch,
    djangodir=djangodir,
    user=user) }}
{% endfor %}


{% endif %}

#{% for subdomain, htpasswd in pillar.htpasswd_by_subdomain.items() %}
#/etc/apache2/htpasswd-{{ subdomain }}:
#  file.managed:
#    - contents_pillar: htpasswd_by_subdomain:{{ subdomain }}
#    - makedirs: True
#{% endfor %}

{% for deploy in pillar.grantnav.deploys %}
/home/grantnav/reload_{{ deploy }}_data.sh:
  file.managed:
    - source: salt://grantnav/reload_data.sh
    - template: jinja
    - mode: 755
    - deploy: {{ deploy }}

/root/reload_{{ deploy }}_data.sh:
  file.managed:
    - contents:
      - '#!/bin/bash'
      - set -e
      - su grantnav -c /home/grantnav/reload_{{ deploy }}_data.sh
    - mode: 755
{% endfor %}

{{ apache('grantnav_default.conf',
    name='000-default.conf') }}


/etc/apache2/mods-available/mpm_event.conf:
  file.managed:
    - source: salt://apache/grantnav_mpm_event.conf
