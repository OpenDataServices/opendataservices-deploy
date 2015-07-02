docker-installed:
    pkg.installed:
        - name: lxc-docker

docker-running:
    service.running:
        {% if grains['lsb_distrib_release']=='14.04' %}
        - name: docker.io
        {% else %}
        - name: docker
        {% endif %}
        - enable: True

{% if grains['lsb_distrib_release']!='14.04' %}
docker-py:
  pkg.installed:
    - name: python-docker
{% endif %}

docker:
  pkgrepo.managed:
    - name: deb https://get.docker.io/ubuntu docker main
    - keyid: 36A1D7869245C8950F966E92D8576A8BA88D21E9
    - keyserver: keyserver.ubuntu.com
