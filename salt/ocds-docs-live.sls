# This is a seperate state for live, because it includes a reverse proxy to hit
# the dev site for dev branches (and Cove for /validator).

include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}
{{ apache('ocds-docs-live.conf') }}
