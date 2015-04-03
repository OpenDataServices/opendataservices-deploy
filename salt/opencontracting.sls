# This is a salt formula to set up the opendataservices website
# ie. http://opendataservices.coop

{% from 'lib.sls' import createuser, apache %}

include:
  - core
  - apache

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'opencontracting' %}
{% set apache_conffile = user + '.conf' %}
{{ createuser(user) }}

opencontracting-deps:
    pkg.installed:
        - pkgs:
            - libapache2-mod-wsgi
            - python-pip
            - python-virtualenv
            - python-dev
            - mysql-server
            - libmysqlclient-dev 
            - libxml2-dev
            - libxslt1-dev
            - mercurial # Required to install django-registration, see
            # https://github.com/open-contracting/standard-collaborator/blob/df98c203217e7dd12f4b9787e12dac02c0d0ec61/deploy/pip_packages.txt#L29

salt-deps:
  pkg.installed:
    - pkgs:
      - python-mysqldb




# For each of the opencontracting python git repos:
#   1) Check out the repo
#   2) Install the required python packages
#   3) Create a database user and database table, and grant the appropirate permissions
#   4) Run the relevant django commands for collecting static files and creating assets
{% for repo in ['standard-collaborator', 'validator', 'opendatacomparison'] %}
https://github.com/OpenDataServices/{{ repo }}.git:
  git.latest:
    - rev: master
    - target: /home/{{ user }}/{{ repo }}/
    - user: {{ user }}
    - require:
      - pkg: git
    - watch_in:
      - service: apache2

{% set djangodir = '/home/' + user + '/' + repo + '/django/website' %}

{{ djangodir }}/.ve/:
  virtualenv.managed:
    - system_site_packages: False
    - requirements: /home/{{ user }}/{{ repo }}/deploy/pip_packages.txt
    - user: {{ user }}
    - require:
      - pkg: opencontracting-deps
    - watch_in:
      - service: apache2

{{ djangodir }}/private_settings.py:
  file.managed:
    - source: salt://django/private_settings.py
    - template: jinja
    - user: {{ user }}
    - context:
      repo: {{ repo }}
    - watch_in:
      - service: apache2

{{ djangodir }}/local_settings.py:
  file.managed:
    - source: salt://django/local_settings.py
    - template: jinja
    - user: {{ user }}
    - context:
      repo: {{ repo }}
    - watch_in:
      - service: apache2

mysql-user-{{ repo[:16] }}:
  mysql_user.present:
    - name: {{ repo[:16] }} # mysql usernames can only be 16 chracters long
    - host: localhost
    - password: {{ pillar[repo].mysql_password }}
    - require:
      - pkg: salt-deps

mysql-database-{{ repo }}:
 mysql_database.present:
  - name: {{ repo }}
 mysql_grants.present:
  - grant: all privileges
  - database: {{ repo }}.*
  - user: {{ repo[:16] }}

syncdb-{{repo}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py syncdb --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}/.ve/
    - onlyif:
      - git: https://github.com/open-contracting/{{ repo }}.git

migrate-{{repo}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py migrate --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}/.ve/
    - onlyif:
      - git: syncdb-{{ repo }}.git

collectstatic-{{repo}}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py collectstatic --noinput
    - user: {{ user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: {{ djangodir }}/.ve/
    - onlyif:
      - git: https://github.com/open-contracting/{{ repo }}.git

{% if repo == 'standard-collaborator' %}
assets-{{ repo }}:
  cmd.run:
    - name: source .ve/bin/activate; python manage.py assets build
    - user: {{ user }}
    - bin_env: {{ djangodir }}/.ve/
    - cwd: {{ djangodir }}
    - require:
      - cmd: collectstatic-{{ repo }}
    - onlyif:
      - cmd: collectstatic-{{ repo }}
{% endif %}

{% endfor %}




# For standard-collaborator we need to create some directories...
{% set standard_workingdir = '/home/'+user+'/standard-collaborator/django/website/working' %}
{% for dirname in ['html', 'exports'] %}
{{ standard_workingdir }}/{{ dirname }}:
  file.directory:
    - makedirs: True
    - user: {{ user }}
{% endfor %}

# ... and check out the standard git repository
https://github.com/open-contracting/standard.git:
  git.latest:
    - rev: master
    - target: {{ standard_workingdir }}/repo
    - user: {{ user }}
    - require:
      - pkg: git




# Set up the Apache config using macro
{{ apache(apache_conffile) }}
