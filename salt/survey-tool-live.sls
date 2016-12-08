{% set user = pillar.username %}

{% from 'lib.sls' import createuser, apache, planio_keys %}

# Create a user, see lib.sls for more info
{{ createuser(user) }}
{{ planio_keys(user) }}

include:
  - core
  - apache

# Apache and PHP setup

{% set servername=pillar.subdomain+pillar.domain %}
{{ apache('survey-tool.conf',
          servername = servername,
          serveraliases = [ 'www.'+servername ],
          https='no') }}

# Don't use php.sls, it explicitly uses php5 and we're on 16.04 php7 here :p
php:
  pkg.installed

survey_tool_apache_php_modules:
  pkg.installed:
    - pkgs:
      - libapache2-mod-php
      - php7.0-xml
      - php7.0-sqlite3
      - php7.0-curl
    - require:
      - pkg: php
      - pkg: apache2
  cmd.run:
    - name: a2enmod rewrite
    - unless: test -f /etc/apache2/mods-enabled/rewrite.load
  file.append:
    - name: /etc/php/7.0/apache2/php.ini
    - text: date.timezone = Europe/London
    - watch_in:
      - service: apache2

# Get the .p12 blob (Google service account key) out of the private pillar and into the home dir

{% set p12path = '/home/'+user+'/'+pillar.p12filename %}

{{ p12path }}.b64:
  file.managed:
    - contents_pillar: p12data
    - group: www-data
    - mode: 640

{{ p12path }}:
  cmd.run:
    - name: base64 -d {{ p12path }}.b64 > {{ p12path }}
    - require:
      - file: {{ p12path }}.b64
    - creates: {{ p12path }}
    - runas: www-data
    - umask: 077

# Pull the git repo. Force it, overwriting any substitutions (below) that will
# probably still be there from a previous deployment.

{% set giturl = 'https://github.com/OpenDataServices/survey-tool.git' %}
{% set gitdest = '/home/'+user+'/survey-tool/' %}

# Don't believe "force_checkout", it's a lie :(
{{ giturl }}:
  cmd.run:
    - name: cd {{ gitdest }}; git checkout -f
  git.latest:
    - rev: {{ pillar.default_branch }}
    - branch: {{ pillar.default_branch }}
    - force_fetch: True
    - force_checkout: True
    - force_reset: True
    - target: {{ gitdest }}
    - user: {{ user }}
    - require:
      - pkg: git
    - watch_in:
      - service: apache2

# File substitutions
# We can't use managed file templates because this stuff all lives in a separate git repo.
# Don't keep backups to avoid spaffing git with untracked files.

replace_master_key:
  file.replace:
    - name: {{ gitdest }}/js/w3f-survey.js
    - pattern: '%MASTER_KEY%'
    - repl: {{ pillar.master_key }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_client_id:
  file.replace:
    - name: {{ gitdest }}/js/w3f-survey.js
    - pattern: '%CLIENT_ID%'
    - repl: {{ pillar.client_id }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_service_account_w3f-survey:
  file.replace:
    - name: {{ gitdest }}/js/w3f-survey.js
    - pattern: '%SERVICE_ACCOUNT%'
    - repl: {{ pillar.service_account }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_service_account_survey-config:
  file.replace:
    - name: {{ gitdest }}/survey-config.php
    - pattern: '%SERVICE_ACCOUNT%'
    - repl: {{ pillar.service_account }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_key_file_location:
  file.replace:
    - name: {{ gitdest }}/survey-config.php
    - pattern: '%KEY_FILE_LOCATION%'
    - repl: {{ p12path }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_protocol_proxy:
  file.replace:
    - name: {{ gitdest }}/proxy/proxy.config
    - pattern: '%PROTOCOL%'
    - repl: {{ pillar.protocol }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_domain_proxy:
  file.replace:
    - name: {{ gitdest }}/proxy/proxy.config
    - pattern: '%DOMAIN%'
    - repl: {{ pillar.subdomain }}{{ pillar.domain }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_protocol_w3f-angular:
  file.replace:
    - name: {{ gitdest }}/js/w3f-angular-spreadsheets.js
    - pattern: '%PROTOCOL%'
    - repl: {{ pillar.protocol }}
    - backup: False
    - require:
      - git: {{ giturl }}

replace_domain_w3f-angular:
  file.replace:
    - name: {{ gitdest }}/js/w3f-angular-spreadsheets.js
    - pattern: '%DOMAIN%'
    - repl: {{ pillar.subdomain }}{{ pillar.domain }}
    - backup: False
    - require:
      - git: {{ giturl }}
