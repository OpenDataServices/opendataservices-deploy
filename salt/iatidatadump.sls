#
# There is no Macro - this can only be installed once per server.
# It needs so many resources we would never be doing that anyway!
#

{% from 'lib.sls' import createuser, apache %}

include:
  - core
  - apache
  - letsencrypt

###################### Dependencies

iatitable-deps:
    apache_module.enabled:
      - name: headers
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - python3-pip
        - python3-virtualenv
        - parallel
        - zip
        - tmux


###################### Vars

{% set user = 'iatidatadump' %}
{% set gitbranch = 'main' %}
{% set app_code_dir = '/home/' +  user + '/iatidatadump' %}
{% set working_dir = '/home/' +  user + '/working_data' %}
{% set web_data_dir = '/home/' +  user + '/web_data' %}
{% set logs_dir = '/home/' +  user + '/logs' %}
{% set data_servername = 'data.iati-data-dump.opendataservices.coop' %}
{% set data_https =  'force' %}

###################### Normal User

{{ createuser(user, world_readable_home_dir='yes') }}


######################  Dirs

{{ working_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

{{ logs_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

###################### App

install_iatidatadump:
  git.latest:
    - name: https://github.com/OpenDataServices/iati-data-dump-2.git
    - rev: {{ gitbranch }}
    - target: {{ app_code_dir }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

{{ app_code_dir }}/.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - require:
      - git: install_iatidatadump

# Fix permissions in virtual env
{{ app_code_dir }}-fix-ve-permissions:
  cmd.run:
    - name: chown -R {{ user }}:{{ user }} .ve
    - runas: root
    - cwd: {{ app_code_dir }}
    - require:
      - virtualenv: {{ app_code_dir }}/.ve/

# This should ideally be in virtualenv.managed but we get an error if we do that
{{ app_code_dir }}-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - runas: {{ user }}
    - cwd: {{ app_code_dir }}
    - require:
      - virtualenv: {{ app_code_dir }}/.ve/


######################  Runner

/home/{{ user }}/runner.sh:
  file.managed:
    - source: salt://iatidatadump/runner.sh
    - template: jinja
    - user: {{ user }}
    - mode: 0755
    - context:
        app_dir: {{ app_code_dir }}
        working_dir: {{ working_dir }}
        web_data_dir: {{ web_data_dir }}
        user: {{ user }}
        logs_dir: {{ logs_dir }}

/home/{{ user }}/runner-with-logging.sh:
  file.managed:
    - source: salt://iatidatadump/runner-with-logging.sh
    - template: jinja
    - user: {{ user }}
    - mode: 0755
    - context:
        app_dir: {{ app_code_dir }}
        working_dir: {{ working_dir }}
        web_data_dir: {{ web_data_dir }}
        user: {{ user }}
        logs_dir: {{ logs_dir }}

/etc/systemd/system/iatidatadump-run.service:
  file.managed:
    - source: salt://iatidatadump/iatidatadump-run.service
    - template: jinja
    - context:
        user: {{ user }}
        app_code_dir: {{ app_code_dir }}
    - requires:
      - user: {{ user }}_user_exists

/etc/systemd/system/iatidatadump-run.timer:
  file.managed:
    - source: salt://iatidatadump/iatidatadump-run.timer
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists
      - file: /etc/systemd/system/iatidatadump-run.service

######################  Web Data Dir

{{ web_data_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

{% set extracontext %}
webserverdir: {{ web_data_dir }}
{% endset %}

{{ apache('iatidatadump-data.conf',
    name='iatidatadump-data.conf',
    extracontext=extracontext,
    servername=data_servername ,
    https=data_https) }}


######################  Systemd final setup

setup_iatidatadump_service:
  cmd.run:
    - name: systemctl daemon-reload ; systemctl enable iatidatadump-run.timer  ; systemctl start iatidatadump-run.timer
    - requires:
      - file: /etc/systemd/system/iatidatadump-run.timer
