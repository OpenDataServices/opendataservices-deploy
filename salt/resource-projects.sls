include:
  - docker
  - apache-proxy

{% from 'lib.sls' import apache %}
{{ apache('resource-projects.conf') }}

{% set dockers = pillar.dockers %}
{% for container, repo in dockers.items() %}
# Temporary workaround to make sure watch for -staging works correctly
# Because otherwise staging has nothing new to pull, and therefore doesn't
# trigger watched state
{% if container != 'lodspeakr-staging' %}
docker-pull-{{ container }}:
  docker.pulled:
    - name: {{ repo }}
    - tag: latest
    - require:
      - sls: docker
    - force: True
    - watch_in:
      - service: docker-{{ container }}
      # See above comment
      {% if container == 'lodspeakr' %}
      - service: docker-lodspeakr-staging
      {% endif %}
{% endif %}
{% endfor %}

{% set container = 'virtuoso' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8890:8890 --volumes-from virtuoso-data
        after: docker
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'etl' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8001:80 --link virtuoso:virtuoso -e "DBA_PASS={{ pillar.virtuoso.password}}" -e FRONTEND_LIVE_URL={{ pillar.frontend_live_url }} -e FRONTEND_STAGING_URL={{ pillar.frontend_staging_url }} --volumes-from etl-data
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'ontowiki' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8000:80 --link virtuoso:virtuoso -e "VIRTUOSO_PASSWORD={{ pillar.virtuoso.password }}"
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'lodspeakr' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8080:80 --link virtuoso:virtuoso-live -e BASE_URL={{ pillar.frontend_live_url }} -e DEFAULT_GRAPH_URI=http://resourceprojects.org/data/  -e SPARQL_ENDPOINT=http://virtuoso-live:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'lodspeakr-staging' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8081:80 --link virtuoso:virtuoso-staging -e BASE_URL={{ pillar.frontend_staging_url }} -e DEFAULT_GRAPH_URI=http://staging.resourceprojects.org/data/ -e SPARQL_ENDPOINT=http://virtuoso-staging:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'lodspeakr-235-speed-up-country-page' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8082:80 --link virtuoso:virtuoso-live -e BASE_URL=http://235-speed-up-country-page.lodspeakr-live.nrgi-dev2.default.opendataservices.uk0.bigv.io/  -e SPARQL_ENDPOINT=http://virtuoso-live:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'lodspeakr-sources' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8083:80 --link virtuoso:virtuoso-live -e BASE_URL=http://sources.lodspeakr-live.nrgi-dev2.default.opendataservices.uk0.bigv.io/  -e SPARQL_ENDPOINT=http://virtuoso-live:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% set container = 'lodspeakr-ontology' %}
{% if container in dockers %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8084:80 --link virtuoso:virtuoso-live -e BASE_URL=http://ontology.lodspeakr-live.nrgi-dev2.default.opendataservices.uk0.bigv.io/  -e SPARQL_ENDPOINT=http://virtuoso-live:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}
{% endif %}

{% for container in dockers %}
# Until the fix for https://github.com/saltstack/salt/pull/24703 is released we
# must have a seperate reload command for each container. Otherwise the
# onchanges would only be called if all changed.
daemon-reload-{{ container }}:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /etc/systemd/system/docker-{{ container }}.service
{% endfor %}

{% for container, repo in dockers.items() %}
docker-{{ container }}:
  service.running:
    - enable: True
    - require:
      - cmd: daemon-reload-{{ container }}
      - docker: {{ repo }}
{% endfor %}

# Should be able to use salt's docker.installed here, but I kept getting
# various python errors
docker create --name virtuoso-data -v /usr/local/var/lib/virtuoso/db {{ dockers.virtuoso }}:
  cmd.run:
    - unless: docker inspect virtuoso-data

docker create --name etl-data -v /usr/src/resource-projects-etl/db/ -v /usr/src/resource-projects-etl/src/cove/media {{ dockers.etl }}:
  cmd.run:
    - unless: docker inspect etl-data

