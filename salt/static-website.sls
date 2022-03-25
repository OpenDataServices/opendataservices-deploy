# This creates a directory that is served by a web server. That's it!
# It's up to some other process to put some actual content in it.
#
# eg add an extra SSH key to the user account and something like a CI server could push content to it

{% from 'lib.sls' import createuser, apache, uwsgi %}

include:
  - core
  - apache
  - uwsgi
  - letsencrypt


{% macro staticwebsite(name, user, directory, servername, https) %}

{% set extracontext %}
user: {{ user }}
directory: {{ directory }}
name: {{ name }}
{% endset %}

{{ createuser(user) }}

/home/{{ user }}/{{ directory }}:
  file.directory:
    - dir_mode: 755
    - file_mode: 644
    - user: {{ user }}
    - group: {{ user }}

{{ apache('static-website.conf',
    name=name+'.conf',
    extracontext=extracontext,
    servername=servername,
    https=https) }}

{% endmacro %}

{% for sws in pillar.static_websites %}
{{ staticwebsite(
    name=sws.name,
    user=sws.user,
    directory=sws.directory,
    servername=sws.servername,
    https=sws.https ) }}
{% endfor %}
