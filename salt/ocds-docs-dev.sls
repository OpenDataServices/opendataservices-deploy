# This is the dev sls for ocds-docs which doesn't include reverse proxying,

include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}
{{ apache('ocds-docs-dev.conf') }}
