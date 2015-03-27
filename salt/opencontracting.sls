{% set user = 'opencontracting' %}

{{ user }}-user-exists:
  user.present:
    - name: {{ user }}
    - home: /home/{{ user }}

git:
  pkg.installed

opencontracting-deps:
    pkg.installed:
        - pkgs:
            - python-pip
            - python-virtualenv
            - python-dev
            - mysql-server
            - libmysqlclient-dev 
            - libxml2-dev
            - libxslt1-dev
            - mercurial # Required to install https://github.com/open-contracting/standard-collaborator/blob/df98c203217e7dd12f4b9787e12dac02c0d0ec61/deploy/pip_packages.txt#L29

{% for repo in ['standard-collaborator', 'validator', 'opendatacomparison'] %}
https://github.com/open-contracting/{{ repo }}.git:
  git.latest:
    - rev: master
    - target: /home/{{ user }}/{{ repo }}/
    - user: {{ user }}
    - require:
      - pkg: git

/home/{{ user }}/{{ repo }}/pyenv/:
    virtualenv.managed:
        - system_site_packages: False
        - requirements: /home/{{ user }}/{{ repo }}/deploy/pip_packages.txt
        - require:
            - pkg: opencontracting-deps
{% endfor %}
