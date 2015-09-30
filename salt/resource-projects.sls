include:
  - docker
  - apache-proxy

{% from 'lib.sls' import apache %}
{{ apache('resource-projects.conf') }}

{% set dockers = {
  'virtuoso': 'caprenter/automated-build-virtuoso',
  'ontowiki': 'bjwebb/ontowiki.docker',
  'lodspeakr': 'opendataservices/resourceprojects.org-frontend:master',
  'etl': 'opendataservices/resource-projects-etl:cove-etl',
} %}

{% for container, repo in dockers.items() %}
{{ repo }}:
  docker.pulled:
    - tag: latest
    - require:
      - sls: docker
    - force: True
    - watch_in:
      - service: docker-{{ container }}
{% endfor %}

{% set container = 'virtuoso' %}
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

{% set container = 'etl' %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }} gunicorn cove.wsgi -b 0.0.0.0:80 --timeout 600
        name: {{ container }}
        extraargs: -p 127.0.0.1:8001:80 --link virtuoso:virtuoso -e "DBA_PASS={{ pillar.virtuoso.password}}"
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}

{% set container = 'ontowiki' %}
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

{% set container = 'lodspeakr' %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}
        extraargs: -p 127.0.0.1:8080:80 --link virtuoso:virtuoso-live -e BASE_URL=http://lodspeakr-live.nrgi-dev2.default.opendataservices.uk0.bigv.io/  -e SPARQL_ENDPOINT=http://virtuoso-live:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}

/etc/systemd/system/docker-{{ container }}-staging.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: {{ dockers[container] }}
        name: {{ container }}-staging
        extraargs: -p 127.0.0.1:8081:80 --link virtuoso:virtuoso-staging -e BASE_URL=http://lodspeakr-staging.nrgi-dev2.default.opendataservices.uk0.bigv.io/  -e SPARQL_ENDPOINT=http://virtuoso-staging:8890/sparql
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}

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

{% set container = 'lodspeakr' %}
{% set repo = dockers[container] %}
docker-{{ container }}-staging:
  service.running:
    - enable: True
    - require:
      - cmd: daemon-reload-{{ container }}
      - docker: {{ repo }}

# Should be able to use salt's docker.installed here, but I kept getting
# various python errors
docker create --name virtuoso-data -v /usr/local/var/lib/virtuoso/db caprenter/automated-build-virtuoso:
  cmd.run:
    - unless: docker inspect virtuoso-data
