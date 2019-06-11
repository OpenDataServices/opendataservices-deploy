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
{{ apache('ocds-docs-dev.conf') }}

# We can't do this yet - it causes problems with hostnames
# https://github.com/open-contracting/standard/issues/878
# { { apache('ocds-docs-dev.conf', servername='dev.standard.open-contracting.org', https='yes' ) } }


add-travis-key-for-ocds-docs-dev:
    ssh_auth.present:
        - user: ocds-docs
        - source: salt://private/ocds-docs/ssh_authorized_keys_from_travis
