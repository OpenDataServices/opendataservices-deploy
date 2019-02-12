{% from 'lib.sls' import createuser %}

{% set user = 'archive' %}
{{ createuser(user) }}
