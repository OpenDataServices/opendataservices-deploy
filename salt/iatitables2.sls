

{% from 'lib.sls' import createuser, apache %}


include:
  - core
  - apache
  - letsencrypt


iatitable-deps:
    pkg.installed:
      - pkgs:
        - python3-pip
        - python3-virtualenv
        - postgresql
        - sqlite3
        - zip
        - s3cmd


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
        - cmd: iatitable-deps-nodejs-2

##################################################################### Normal User

{% set user = 'iatitables' %}
{{ createuser(user) }}

##################################################################### Macro to install app

{% macro iatitables(gitbranch, user, postgres_name, postgres_user, postgres_password) %}

######################  Working Dir

{% set working_dir = '/home/' +  user + '/data' %}

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

{% set app_code_dir = '/home/' +  user + '/iatitables' %}

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
{{ app_code_dir }}-install-python-packages:
  cmd.run:
    - name: . .ve/bin/activate; pip install -r requirements.txt
    - user: {{ user }}
    - cwd: {{ app_code_dir }}
    - require:
      - virtualenv: {{ app_code_dir }}/.ve/

{{ app_code_dir }}/runner.py:
  file.managed:
    - source: salt://iatitables/runner.py
    - template: jinja
    - user: {{ user }}
    - context:
        processes: 1
        dir: {{ working_dir }}
        db_url: postgresql://{{ postgres_user }}:{{ postgres_password }}@localhost/{{ postgres_name }}


###################### Website contents

{{ app_code_dir }}-build-website:
  cmd.run:
    - name: yarn install; yarn build
    - user: {{ user }}
    - cwd: {{ app_code_dir }}/site
    - require:
      - git: install_iatitables


{% endmacro %}

##################################################################### Run Macro Once for app


{{ iatitables(
    gitbranch=pillar.iatitables.gitbranch if 'gitbranch' in pillar.iatitables else 'main',
    user=user,
    postgres_name=pillar.iatitables.postgres_name if 'postgres_name' in pillar.iatitables else 'iatitables',
    postgres_user=pillar.iatitables.postgres_user if 'postgres_user' in pillar.iatitables else 'iatitables',
    postgres_password=pillar.iatitables.postgres_password if 'postgres_password' in pillar.iatitables else '1234',
    ) }}
