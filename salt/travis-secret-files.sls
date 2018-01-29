# This is a salt formula to set up the opendataservices website
# ie. http://opendataservices.coop

{% from 'lib.sls' import createuser, apache, planio_keys %}

include:
  - core
  - apache

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'travis-secret-files' %}
{{ createuser(user) }}

# Set up the Apache config using macro
{{ apache('travis-secret-files.conf') }}

/etc/apache2/htpasswd-travis:
  file.managed:
    - contents_pillar: travis:htpasswd
    - makedirs: True
