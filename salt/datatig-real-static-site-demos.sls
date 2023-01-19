#
# The first time you install it this won't build any content, so links will 404.
# Either just wait for the cron to activate, or log in and run /home/datatig/build-real-staticsite-demos.sh as the datatig user by hand.
#

{% from 'lib.sls' import createuser, apache %}

include:
  - apache
  - letsencrypt

# This is hard coded in some places, sorry
{% set user="datatig" %}

{{ createuser(user, world_readable_home_dir='yes') }}


/home/{{ user }}/real-staticsite-demos:
  git.latest:
    - name: https://github.com/DataTig/real-staticsite-demos.git
    - rev: main
    - user: {{ user }}
    - target: /home/{{ user }}/real-staticsite-demos
    - force_fetch: True
    - force_reset: True
    - submodules: True
    - require:
      - pkg: git

/home/{{ user }}/real-staticsite-demos/.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - require:
      - git: /home/{{ user }}/real-staticsite-demos

# Fix permissions in whole folder (inc virtual env)
{{ user }}fix-ve-permissions:
  cmd.run:
    - name: chown -R {{ user }}:{{ user }} real-staticsite-demos
    - user: root
    - cwd: /home/{{ user }}
    - require:
      - virtualenv: /home/{{ user }}/real-staticsite-demos/.ve/

/home/{{user}}/build-real-staticsite-demos.sh:
  file.managed:
    - source: salt://datatig-real-static-site-demos/build.sh
    - mode: 700
    - user: {{ user }}
    - group: {{ user }}
    - template: jinja
    - context:
        user: {{ user }}

# Cron for building regularly
datatig-real-static-site-demos-cron:
  cron.present:
    - name: "/home/{{ user }}/build-real-staticsite-demos.sh >  /home/{{ user }}/real-staticsite-demos.log 2>&1"
    - identifier: DATATIG_REAL_STATIC_SITE_DEMOS
    - user: {{ user }}
    - minute: 0
    - hour: 4

# Serve static website
{{ apache(user+'-real-staticsite-demos.conf',
    name=user+'-real-staticsite-demos.conf',
    servername='datatig-rsd.' + grains.fqdn,
    https='force') }}
