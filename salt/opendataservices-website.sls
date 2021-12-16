# This is a salt formula to set up the opendataservices website
# ie. http://opendataservices.coop

{% from 'lib.sls' import createuser, apache, planio_keys %}

include:
  - core
  - apache
  - docker
{% if 'https' in pillar.opendataservices_website and pillar.opendataservices_website.https %}  - letsencrypt{% endif %}

rewrite:
  apache_module.enabled

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'opendataservices' %}
{{ createuser(user) }}

/home/{{ user }}/.ssh/config:
  file.managed:
    - source: salt://private/opendataservices-website/ssh-config
    - makedirs: True
    - mode: 600
    - user: {{ user }}
    - group: {{ user }}

/home/{{ user }}/.ssh/id-opendataservices-website:
  file.managed:
    - source: salt://private/opendataservices-website/id_ed25519
    - makedirs: True
    - mode: 600
    - user: {{ user }}
    - group: {{ user }}

/home/{{ user }}/.ssh/id-opendataservices-website-pub.pub:
  file.managed:
    - source: salt://private/opendataservices-website/id_ed25519.pub
    - makedirs: True
    - mode: 600
    - user: {{ user }}
    - group: {{ user }}

# This content got from running "ssh-keyscan  github.com"
/home/{{ user }}/.ssh/known_hosts:
  file.append:
    - text:
      - "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="

# Download the repository
git@github.com:OpenDataServices/coop-website.git:
  git.latest:
    - rev: {{ pillar.opendataservices_website.default_branch }}
    - target: /home/{{ user }}/website/
    - user: {{ user }}
    - submodules: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git
      - file: /home/{{ user }}/.ssh/known_hosts
      - file: /home/{{ user }}/.ssh/id-opendataservices-website

# Build the site
build_coop_website:
    cmd.run:
        # Reason for mkdir: https://github.com/jekyll/jekyll/issues/7591
        - name: mkdir -p .jekyll-cache _site && docker run --rm --label=jekyll --volume=/home/{{ user }}/website/:/srv/jekyll jekyll/jekyll:stable jekyll build && chown -R opendataservices:opendataservices _site/
        - cwd: /home/{{ user }}/website/
        - runas: root
        - env:
           - TZ: 'Europe/London'
        - require:
          - git: git@github.com:OpenDataServices/coop-website.git

# Set up the Apache config using macro
{{ apache('opendataservices-website.conf','','','',pillar.opendataservices_website.servername,pillar.opendataservices_website.serveraliases,pillar.opendataservices_website.https) }}
