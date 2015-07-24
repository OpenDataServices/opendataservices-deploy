include:
  - docker
  - apache-proxy

{% from 'lib.sls' import apache %}
{{ apache('resource-projects.conf') }}

{% set dockers = {
  'virtuoso': 'caprenter/automated-build-virtuoso',
  'ontowiki': 'bjwebb/ontowiki.docker',
  'lodspeakr': 'bjwebb/resourceprojects.org-frontend'
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
        image: caprenter/automated-build-virtuoso
        name: {{ container }}
        extraargs: -p 127.0.0.1:8890:8890 --volumes-from virtuoso-data
        after: docker
    - watch_in:
      - service: docker-{{ container }}

{% set container = 'ontowiki' %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: bjwebb/ontowiki.docker
        name: {{ container }}
        extraargs: -p 127.0.0.1:8000:80 --link virtuoso:virtuoso
        after: docker-virtuoso
    - watch_in:
      - service: docker-{{ container }}

{% set container = 'lodspeakr' %}
/etc/systemd/system/docker-{{ container }}.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: bjwebb/resourceprojects.org-frontend
        name: {{ container }}
        extraargs: -p 127.0.0.1:8080:80 --link virtuoso:virtuoso -e BASE_URL=http://alpha.resourceprojects.org/
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

# Should be able to use salt's docker.installed here, but I kept getting
# various python errors
docker create --name virtuoso-data -v /usr/local/var/lib/virtuoso/db caprenter/automated-build-virtuoso:
  cmd.run:
    - unless: docker inspect virtuoso-data
