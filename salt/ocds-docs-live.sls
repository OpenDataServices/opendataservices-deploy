# This is a seperate salt SLS file for live, because it includes a reverse
# proxy to hit the dev site for dev branches (and Cove for /validator).
# See apache/ocds-docs-live.conf
#
# For info on how to do a live deploy, see:
# https://ocds-standard-development-handbook.readthedocs.io/en/latest/deployment/standard-live/

include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}
{{ apache('ocds-docs-live.conf') }}
{{ apache('ocds-docs-live-new.conf') }}

https://github.com/open-contracting/standard-legacy-staticsites.git:
  git.latest:
    - rev: master
    - target: /home/ocds-docs/web/legacy/
    - user: ocds-docs
    - force_fetch: True
    - force_reset: True

/home/ocds-docs/web/robots.txt:
  file.managed:
    - source: salt://ocds-docs/robots_live.txt
    - user: ocds-docs
