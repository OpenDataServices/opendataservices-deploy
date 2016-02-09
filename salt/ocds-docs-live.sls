# This is a seperate state for live, because it includes a reverse proxy to hit
# the dev site for dev branches (and Cove for /validator).

include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}
{{ apache('ocds-docs-live.conf') }}

https://github.com/open-contracting/standard-legacy-staticsites.git:
  git.latest:
    - rev: master
    - target: /home/ocds-docs/web/legacy/
    - user: ocds-docs
    - force_fetch: True
    - force_reset: True

mod_include:
  apache_module.enable:
    - name: include
