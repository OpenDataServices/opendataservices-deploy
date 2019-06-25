# This is the dev sls for ocds-docs which doesn't include reverse proxying,
#
# The docs on this server are built and copied to travis.
#   https://github.com/open-contracting/standard/blob/1.1/.travis.yml
#
# The travis config pulls in a shell script from this deploy repository (so
# that we don't have to make deployment changes to every single branch we might
# want to build).
#   https://github.com/OpenDataServices/opendataservices-deploy/blob/master/open-contracting-standard-deploy.sh
# 
# Note that this means that anyone with push access to the open-contracting
# GitHub repo can cause files to be copied to this server.

include:
  - ocds-docs-common
  - letsencrypt

{% from 'lib.sls' import apache %}

# This is the "live" server setup.

{% set extracontext %}
testing: False
{% endset %}

{{ apache('ocds-docs-staging.conf',
    name='ocds-docs-staging.conf',
    extracontext=extracontext,
    socket_name='',
    servername='staging.standard.open-contracting.org',
    serveraliases=[],
    https='yes') }}

# This is the "testing" server setup.
# If you need to mess around with the apache configs (maybe you need to test some redirects or proxy options) use this please.

{% set extracontext %}
testing: True
{% endset %}

{{ apache('ocds-docs-staging.conf',
    name='ocds-docs-staging-testing.conf',
    extracontext=extracontext,
    socket_name='',
    servername='testing.staging.standard.open-contracting.org',
    serveraliases=[],
    https='yes') }}

# And now other misc stuff .....

add-travis-key-for-ocds-docs-dev:
    ssh_auth.present:
        - user: ocds-docs
        - source: salt://private/ocds-docs/ssh_authorized_keys_from_travis
