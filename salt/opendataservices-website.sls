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
{{ createuser(user, world_readable_home_dir='yes') }}

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
      - "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk="

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
        - name: mkdir -p .jekyll-cache _site && docker run --rm --label=jekyll --env TZ=Europe/London  --volume=/home/{{ user }}/website/:/srv/jekyll jekyll/jekyll:stable jekyll build && chown -R opendataservices:opendataservices _site/
        - cwd: /home/{{ user }}/website/
        - runas: root
        - require:
          - git: git@github.com:OpenDataServices/coop-website.git

# Set up the Apache config using macro
{{ apache('opendataservices-website.conf','','','',pillar.opendataservices_website.servername,pillar.opendataservices_website.serveraliases,pillar.opendataservices_website.https) }}
