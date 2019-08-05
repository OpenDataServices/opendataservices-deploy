# This is a seperate salt SLS file for live, because it includes a reverse
# proxy to hit the dev site for dev branches (and Cove for /validator).
# See apache/ocds-docs-live.conf
#
# For info on how to do a live deploy, see:
# https://ocds-standard-development-handbook.readthedocs.io/en/latest/deployment/standard-live/

include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}

# This is the "live" server setup.

{% set extracontext %}
testing: False
{% endset %}

# When https is changed to FORCE there is a block in salt/apache/ocds-docs-live.conf.include that can be deleted too.
# It is commited in the same commit as this comment, check the commit out.

{{ apache('ocds-docs-live.conf',
    name='ocds-docs-live.conf',
    extracontext=extracontext,
    socket_name='',
    servername='standard.open-contracting.org',
    serveraliases=[],
    https='force') }}

# This is the "testing" server setup.
# If you need to mess around with the apache configs (maybe you need to test some redirects or proxy options) use this please.

{% set extracontext %}
testing: True
{% endset %}

{{ apache('ocds-docs-live.conf',
    name='ocds-docs-live-testing.conf',
    extracontext=extracontext,
    socket_name='',
    servername='testing.live.standard.open-contracting.org',
    serveraliases=[],
    https='force') }}


# And now other misc stuff .....

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
