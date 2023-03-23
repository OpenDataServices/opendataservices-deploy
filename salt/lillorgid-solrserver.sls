
{% from 'lib.sls' import createuser, apache %}

include:
  - apache
  - apache-proxy
  - letsencrypt

solr-server-deps:
    pkg.installed:
      - pkgs:
        - curl
        - default-jdk

{% set user = 'lillorgidsolr' %}
{{ createuser(user, world_readable_home_dir='yes') }}

########### Get binary

get_solr:
  cmd.run:
    - name: curl -L https://www.apache.org/dyn/closer.lua/solr/solr/9.1.1/solr-9.1.1.tgz?action=download -o /home/{{ user }}/solr-9.1.1.tgz
    - creates: /home/{{ user }}/solr-9.1.1.tgz
    - requires:
      - pkg.prometheus-server-deps
      - user: {{ user }}_user_exists

extract_solr:
  cmd.run:
    - name: tar xvzf solr-9.1.1.tgz
    - creates: /home/{{ user }}/solr-9.1.1/CHANGES.txt
    - cwd: /home/{{ user }}/
    - requires:
      - cmd.get_solr


########### Data

/home/{{ user }}/data:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True
    - requires:
      - user: {{ user }}_user_exists


/home/{{ user }}/logs:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - makedirs: True
    - requires:
      - user: {{ user }}_user_exists


########### Service

/etc/systemd/system/solr.service:
  file.managed:
    - source: salt://lillorgid/solr.service
    - template: jinja
    - context:
        user: {{ user }}
    - requires:
      - user: {{ user }}_user_exists

# systemctl daemon-reload ?????????????????????

# Service running stuff TODO

########### Apache Reverse Proxy with password for security

{% set extracontext %}
user: {{ user }}
{% endset %}

{{ apache('lillorgid-solr.conf',
    name='lillorgid-solr.conf',
    extracontext=extracontext,
    servername=pillar.lillorgidsolr.server_fqdn,
    https=pillar.lillorgidsolr.server_https ) }}

solr-server-apache-password:
  cmd.run:
    - name: rm /home/{{ user }}/htpasswd ; htpasswd -c -b /home/{{ user }}/htpasswd solr {{ pillar.lillorgidsolr.server_password }}
    - runas: {{ user }}
    - cwd: /home/{{ user }}


# su lillorgidsolr
# /home/lillorgidsolr/solr-9.1.1/bin/solr create_core -p 8983 -c lillorgidlists -d _default
# /home/lillorgidsolr/solr-9.1.1/bin/solr create_core -p 8983 -c lillorgiddata -d _default

