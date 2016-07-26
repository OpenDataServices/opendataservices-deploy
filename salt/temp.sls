{% from 'lib.sls' import apache, createuser %}

{{ apache('temp.conf') }}
{% set user = 'temp' %}
{{ createuser(user) }}

/home/{{ user }}/web/:
  file.directory:
    - user: {{ user }}
    - makedirs: True
    - mode: 755
