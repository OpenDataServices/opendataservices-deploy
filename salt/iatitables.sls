caddy-pkgrepo:
  pkgrepo.managed:
    - humanname: Caddy
    - name: 'deb https://dl.cloudsmith.io/public/caddy/stable/deb/debian "any-version" main'
    - file: /etc/apt/sources.list.d/caddy-stable.list
    - require_in:
      - pkg: iatitables-deps
    - gpgcheck: 1
    - key_url: https://dl.cloudsmith.io/public/caddy/stable/gpg.key


iatitables-deps:
    pkg.installed:
      - pkgs:
        {% if grains['osrelease'] == '18.04' or grains['osrelease'] == '16.04' %}
        - python-pip
        - python-virtualenv
        {% endif %}
        {% if grains['osrelease'] == '20.04' %}
        - python3-pip
        - python3-virtualenv
        - gcc
        - libxslt1-dev
        {% endif %}
        - git
        - python3-dev
        - sqlite3
        - caddy

caddy:
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - iatitables-deps


/etc/caddy/Caddyfile:
  file.managed:
    - source: salt://caddy/reverse8080.caddyfile
    - template: jinja


{% set iatitables_ve = '/home/iatitables/datasette/.ve' %}

{{iatitables_ve}}:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: iatitables
    - system_site_packages: False

iatitables-pip:
  cmd.wait:
    - name: "{{iatitables_ve}}/bin/pip install datasette datasette-vega"
    - cwd: /home/iatitables/datasette/
    - runas: iatitables
    - watch:
      - virtualenv: {{iatitables_ve}}


/home/iatitables/iatitables.env:
  file.managed:
    - source: salt://private/env/iatitables.env
    - template: jinja

/etc/cron.daily/iatitables:
  file.managed:
    - source: salt://iati-misc/iatitables
    - mode: 755
    - template: jinja


/etc/systemd/system/iati-datasette.service:
  file.managed:
    - source: salt://systemd/iati-datasette.service
    - template: jinja
    - require:
      - /home/iatitables/iatitables.env
      - iatitables-pip

iati-datasette:
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - /etc/systemd/system/iati-datasette.service

