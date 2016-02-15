# This is the dev sls for ocds-docs which doesn't include reverse proxying,
#
# The docs on this server are built and copied it to travis.
# https://github.com/open-contracting/standard/blob/1.0/.travis.yml
# The travis config pulls in a shell script from this deploy repository (so
# that we don't have to make deployment changes to every single branch we might
# want to build).
# https://github.com/OpenDataServices/opendataservices-deploy/blob/master/open-contracting-standard-deploy.sh

include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}
{{ apache('ocds-docs-dev.conf') }}
