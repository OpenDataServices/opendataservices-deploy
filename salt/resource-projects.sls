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

/etc/systemd/system/docker-virtuoso.service:
  file.managed:
    - source: salt://systemd/docker-run.service
    - template: jinja
    - context:
        image: caprenter/automated-build-virtuoso
        name: virtuoso
        extraargs: -p 127.0.0.1:8890:8890

systemctl daemon-reload:
  cmd.run:
    - onchanges:
      - file: /etc/systemd/system/docker-virtuoso.service

docker-virtuoso:
  service.running:
    - enable: True
    - require:
      - cmd: systemctl daemon-reload
      - docker: caprenter/automated-build-virtuoso
