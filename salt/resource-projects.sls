include:
  - docker
  - apache-proxy

{% from 'lib.sls' import apache %}
{{ apache('resource-projects.conf') }}

caprenter/automated-build-virtuoso:
  docker.pulled:
    - tag: latest
    - require:
      - sls: docker

bjwebb/ontowiki.docker:
  docker.pulled:
    - tag: latest
    - require:
      - sls: docker

/etc/systemd/system/docker-virtuoso.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: caprenter/automated-build-virtuoso
        name: virtuoso
        extraargs: -p 127.0.0.1:8890:8890

/etc/systemd/system/docker-ontowiki.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: bjwebb/ontowiki.docker
        name: ontowiki
        extraargs: -p 127.0.0.1:8000:80 --link virtuoso:virtuoso

systemctl daemon-reload:
  cmd.run:
    - onchanges:
      - file: /etc/systemd/system/*

docker-virtuoso:
  service.running:
    - enable: True
    - require:
      - cmd: systemctl daemon-reload
      - docker: caprenter/automated-build-virtuoso

docker-ontowiki:
  service.running:
    - enable: True
    - require:
      - cmd: systemctl daemon-reload
      - docker: bjwebb/ontowiki.docker
