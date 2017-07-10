{% from 'lib.sls' import apache %}
{{ apache('cove_dev_redirects.conf') }}
