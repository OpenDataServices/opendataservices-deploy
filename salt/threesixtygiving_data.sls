{% from 'lib.sls' import apache, createuser %}
{{ apache('threesixtygiving_data.conf') }}

{% set user = 'threesixtygiving_data' %}
{{ createuser(user) }}
