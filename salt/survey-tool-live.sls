{% set user = pillar.username %}

{% from 'lib.sls' import createuser, apache, planio_keys %}

# Create a user, see lib.sls for more info
{{ createuser(user) }}
{{ planio_keys(user) }}

include:
  - core
  - apache

# Set up the Apache config using macro
{{ apache('survey-tool.conf') }}

# php setup
# we won't use php.sls, as that explicitly uses php5 and we're on 16.04 php7 here :p

php:
  pkg.installed

libapache2-mod-php:
  pkg.installed

#### TODO: For some reason this also needs 'a2enmod rewrite'

/etc/php/7.0/apache2/php.ini:
  file.append:
    - text: date.timezone = Europe/London
    - watch_in: apache2
    - require:
      - pkg: libapache2-mod-php

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

{{ giturl }}:
  git.latest:
    - rev: {{ pillar.default_branch }}
    - force_fetch: True;
    - force_checkout: True;
    - force_reset: True;
    - target: {{ gitdest }}
    - user: {{ user }}
    - require:
      - pkg: git
    - watch_in:
      - service: apache2

# File substitutions
# No, beloved Salt devs, we can't use your precious managed file templates
# because this stuff all lives in its own git repo :(

replace_master_key:
  file.replace:
    - name: {{ gitdest }}/js/w3f-survey.js
    - pattern: '%MASTER_KEY%'
    - repl: {{ pillar.master_key }}
    - require:
      - git: {{ giturl }}

replace_client_id:
  file.replace:
    - name: {{ gitdest }}/js/w3f-survey.js
    - pattern: '%CLIENT_ID%'
    - repl: {{ pillar.client_id }}
    - require:
      - git: {{ giturl }}

replace_service_account_w3f-survey:
  file.replace:
    - name: {{ gitdest }}/js/w3f-survey.js
    - pattern: '%SERVICE_ACCOUNT%'
    - repl: {{ pillar.service_account }}
    - require:
      - git: {{ giturl }}

replace_service_account_survey-config:
  file.replace:
    - name: {{ gitdest }}/survey-config.php
    - pattern: '%SERVICE_ACCOUNT%'
    - repl: {{ pillar.service_account }}
    - require:
      - git: {{ giturl }}

replace_key_file_location:
  file.replace:
    - name: {{ gitdest }}/survey-config.php
    - pattern: '%KEY_FILE_LOCATION%'
    - repl: {{ p12path }}
    - require:
      - git: {{ giturl }}

replace_protocol_proxy:
  file.replace:
    - name: {{ gitdest }}/proxy/proxy.config
    - pattern: '%PROTOCOL%'
    - repl: {{ pillar.protocol }}
    - require:
      - git: {{ giturl }}

replace_domain_proxy:
  file.replace:
    - name: {{ gitdest }}/proxy/proxy.config
    - pattern: '%DOMAIN%'
    - repl: {{ pillar.subdomain }}{{ pillar.domain }}
    - require:
      - git: {{ giturl }}

replace_protocol_w3f-angular:
  file.replace:
    - name: {{ gitdest }}/js/w3f-angular-spreadsheets.js
    - pattern: '%PROTOCOL%'
    - repl: {{ pillar.protocol }}
    - require:
      - git: {{ giturl }}

replace_domain_w3f-angular:
  file.replace:
    - name: {{ gitdest }}/js/w3f-angular-spreadsheets.js
    - pattern: '%DOMAIN%'
    - repl: {{ pillar.subdomain }}{{ pillar.domain }}
    - require:
      - git: {{ giturl }}
