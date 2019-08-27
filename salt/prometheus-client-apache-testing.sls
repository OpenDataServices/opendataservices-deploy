#
# THIS IS NOT FOR REAL SERVERS!!!
# PUT THIS ON YOUR TEST VM ONLY!!!
#
# It creates a dummy end point which is just a static text file.
# You can edit it by hand to "change" a server being monitored, and thus test alert rules!
# The config for the dummy end point is in salt/prometheus-server-server/conf-prometheus.yml, but commented out.
#

{% from 'lib.sls' import createuser, apache %}

include:
  - apache

{% set user = 'prometheus-client-testing' %}
{{ createuser(user) }}

########### Content

/home/{{ user }}/web/metrics:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True
    - requires:
      - user: {{ user }}_user_exists

/home/{{ user }}/web/metrics/index.html:
  file.managed:
    - source: salt://prometheus-client-testing/results.txt
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - file: /home/{{ user }}/web/metrics


########### Apache


{% set extracontext %}
user: {{ user }}
{% endset %}

{{ apache('prometheus-client-testing.conf',
    name='prometheus-client-testing.conf',
    extracontext=extracontext ) }}



