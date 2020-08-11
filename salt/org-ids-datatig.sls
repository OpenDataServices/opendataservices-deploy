{% from 'lib.sls' import createuser, apache, uwsgi %}

{% set user = 'org-ids-datatig' %}
{{ createuser(user) }}

# All hosting is currently done on Netlify
# But we just want a cron task to trigger a build every night

curl -X POST -d {} {{ pillar.org_ids_datatig.netlify_build_url }}:
  cron.present:
    - identifier: TRIGGER_NETLIFY_BUILD
    - user: {{ user }}
    - minute: random
    - hour: 5

