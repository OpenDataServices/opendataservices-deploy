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
      - name: proxy proxy_http headers
      - watch_in:
        - service: apache2
    pkg.installed:
      - pkgs:
        - python3-pip
        - python3-virtualenv
        - postgresql
        - sqlite3
        - zip


iatitable-deps-nodejs-1:
  cmd.run:
    - name: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    - user: root
    - creates: /etc/apt/sources.list.d/nodesource.list

iatitable-deps-nodejs-2:
    pkg.installed:
      - pkgs:
        - nodejs
      - require:
        - cmd: iatitable-deps-nodejs-1

iatitable-deps-yarn:
  cmd.run:
    - name: npm install -g yarn
    - user: root
    - creates: /usr/bin/yarn
    - require:
        - pkg: iatitable-deps-nodejs-2

###################### Vars

{% set user = 'iatitables' %}
{% set gitbranch = pillar.iatitables.gitbranch if 'gitbranch' in pillar.iatitables else 'main' %}
{% set postgres_name = pillar.iatitables.postgres_name if 'postgres_name' in pillar.iatitables else 'iatitables' %}
{% set postgres_user = pillar.iatitables.postgres_user if 'postgres_user' in pillar.iatitables else 'iatitables' %}
{% set postgres_password = pillar.iatitables.postgres_password if 'postgres_password' in pillar.iatitables else '1234' %}
{% set web_servername = pillar.iatitables.web_servername if 'web_servername' in pillar.iatitables else 'iatitables.opendataservices.coop' %}
{% set web_https =  pillar.iatitables.web_https if 'web_https' in pillar.iatitables else 'no' %}
{% set data_servername = pillar.iatitables.data_servername if 'data_servername' in pillar.iatitables else 'data.iatitables.opendataservices.coop' %}
{% set data_https =  pillar.iatitables.data_https if 'data_https' in pillar.iatitables else 'no' %}
{% set datasette_servername = pillar.iatitables.datasette_servername if 'datasette_servername' in pillar.iatitables else 'datasette.iatitables.opendataservices.coop' %}
{% set datasette_https =  pillar.iatitables.datasette_https if 'datasette_https' in pillar.iatitables else 'no' %}
{% set datasette_secret =  pillar.iatitables.datasette_secret if 'datasette_secret' in pillar.iatitables else 'abc123' %} # Don't use on prod!
{% set working_dir = '/home/' +  user + '/working_data' %}
{% set app_code_dir = '/home/' +  user + '/iatitables' %}
{% set web_data_dir = '/home/' +  user + '/web_data' %}
{% set datasette_dir = '/home/' +  user + '/datasette' %}

###################### Normal User

{{ createuser(user, world_readable_home_dir='yes') }}

######################  Working Dir

{{ working_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

######################  Database

#iatitables-database-user-{{ postgres_user }}:
#  postgres_user.present:
#    - name: {{ postgres_user }}
#    - password: {{ postgres_password }}
# TODO Does this set password properly?????


#iatitables-database-exists-{{ postgres_name }}:
#  postgres_database.present:
#    - name: {{ postgres_name }}
#    - owner: {{ postgres_user }}
#    - require:
#      - postgres_user: iatitables-database-user-{{ postgres_user }}



###################### App

install_iatitables:
  git.latest:
    - name: https://github.com/codeforIATI/iati-tables.git
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
      - git: install_iatitables

# Fix permissions in virtual env
{{ app_code_dir }}-fix-ve-permissions:
  cmd.run:
    - name: chown -R {{ user }}:{{ user }} .ve
    - user: root
    - cwd: {{ app_code_dir }}
    - require:
      - virtualenv: {{ app_code_dir }}/.ve/

# This should ideally be in virtualenv.managed but we get an error if we do that
# Must install via setup! https://github.com/codeforIATI/iati-tables/issues/9
{{ app_code_dir }}-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -e .
    - user: {{ user }}
    - cwd: {{ app_code_dir }}
    - require:
      - virtualenv: {{ app_code_dir }}/.ve/


###################### Website contents

{{ app_code_dir }}/fix_website_links.sh:
  file.managed:
    - source: salt://iatitables/fix_website_links.sh
    - template: jinja
    - user: {{ user }}
    - mode: 0755
    - context:
        data_url: http{% if data_https == 'yes' or data_https == 'force' %}s{% endif %}://{{ data_servername }}
        datasette_url: http{% if datasette_https == 'yes' or datasette_https == 'force' %}s{% endif %}://{{ datasette_servername }}
        template_dir: {{ app_code_dir }}/site/src/views
    - require:
      - git: install_iatitables

run_fix_website_links:
  cmd.run:
    - name: ./fix_website_links.sh
    - user: {{ user }}
    - cwd: {{ app_code_dir }}
    - require:
      - file: {{ app_code_dir }}/fix_website_links.sh

{{ app_code_dir }}-build-website:
  cmd.run:
    - name: yarn install; yarn build
    - user: {{ user }}
    - cwd: {{ app_code_dir }}/site
    - env:
        NODE_OPTIONS: "--openssl-legacy-provider"
    - require:
        - cmd: run_fix_website_links

{% set extracontext %}
webserverdir: {{ app_code_dir }}/site/dist
{% endset %}

{{ apache('iatitables-web.conf',
    name='iatitables-web.conf',
    extracontext=extracontext,
    servername=web_servername ,
    https=web_https) }}

######################  Log Dir

{% set logs_dir = '/home/' +  user + '/logs' %}

{{ logs_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

######################  Web Data Dir

{{ web_data_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True

{% set extracontext %}
webserverdir: {{ web_data_dir }}
{% endset %}

{{ apache('iatitables-data.conf',
    name='iatitables-data.conf',
    extracontext=extracontext,
    servername=data_servername ,
    https=data_https) }}

######################  Runner

{{ app_code_dir }}/runner.py:
  file.managed:
    - source: salt://iatitables/runner.py
    - template: jinja
    - user: {{ user }}
    - context:
        processes: 1
        dir: {{ working_dir }}

{{ app_code_dir }}/runner.sh:
  file.managed:
    - source: salt://iatitables/runner.sh
    - template: jinja
    - user: {{ user }}
    - mode: 0755
    - context:
        app_dir: {{ app_code_dir }}
        working_dir: {{ working_dir }}
        web_data_dir: {{ web_data_dir }}
        dir: {{ working_dir }}
        db_url: postgresql://{{ postgres_user }}:{{ postgres_password }}@localhost/{{ postgres_name }}

{{ app_code_dir }}/runner-with-logging.sh:
  file.managed:
    - source: salt://iatitables/runner-with-logging.sh
    - template: jinja
    - user: {{ user }}
    - mode: 0755
    - context:
        app_dir: {{ app_code_dir }}
        logs_dir: {{ logs_dir }}

/etc/systemd/system/iatitables-run.service:
  file.managed:
    - source: salt://iatitables/iatitables-run.service
    - template: jinja
    - context:
        user: {{ user }}
        app_code_dir: {{ app_code_dir }}
    - requires:
      - user: {{ user }}_user_exists

/etc/systemd/system/iatitables-run.timer:
  file.managed:
    - source: salt://iatitables/iatitables-run.timer
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists
      - file: /etc/systemd/system/iatitables-run.service

######################  Datasette

{{ datasette_dir }}/.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - require:
        - user: {{ user }}_user_exists

# Fix permissions in virtual env
{{ datasette_dir }}-fix-ve-permissions:
  cmd.run:
    - name: chown -R {{ user }}:{{ user }} .ve
    - user: root
    - cwd: {{ datasette_dir }}
    - require:
      - virtualenv: {{ datasette_dir }}/.ve/

# This should ideally be in virtualenv.managed but we get an error if we do that
{{ datasette_dir }}-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install datasette==0.64.5 datasette-vega==0.6.2
    - user: {{ user }}
    - cwd: {{ datasette_dir }}
    - require:
      - virtualenv: {{ datasette_dir }}/.ve/


{{ datasette_dir }}/iatitables-datasette.env:
  file.managed:
    - source: salt://iatitables/iatitables-datasette.env
    - template: jinja
    - context:
        secret: {{ datasette_secret }}
    - require:
      - virtualenv: {{ datasette_dir }}/.ve/

/etc/systemd/system/iatitables-datasette.service:
  file.managed:
    - source: salt://iatitables/iatitables-datasette.service
    - template: jinja
    - context:
        user: {{ user }}
        datasette_dir: {{ datasette_dir }}
        web_data_dir: {{ web_data_dir }}
    - requires:
      - user: {{ user }}_user_exists

{% set extracontext %}
{% endset %}

{{ apache('iatitables-datasette.conf',
    name='iatitables-datasette.conf',
    extracontext=extracontext,
    servername=datasette_servername ,
    https=datasette_https) }}

######################  Systemd final setup

setup_iatitables_service:
  cmd.run:
    - name: systemctl daemon-reload ; systemctl enable iatitables-run.timer  ; systemctl start iatitables-run.timer ; systemctl enable iatitables-datasette.service ;  systemctl start iatitables-datasette.service
    - requires:
      - file: /etc/systemd/system/iatitables-run.timer