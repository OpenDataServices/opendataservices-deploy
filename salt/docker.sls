docker-installed:
    pkg.installed:
        - name: docker.io

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
