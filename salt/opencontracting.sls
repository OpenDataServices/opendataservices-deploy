# This is a salt formula to set up the opendataservices website
# ie. http://opendataservices.coop

{% from 'lib.sls' import createuser %}

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'opencontracting' %}
{{ createuser(user) }}

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

# For each of the opencontracting python git repos:
#   1) Check out the repo
#   2) Install the required python packages
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
