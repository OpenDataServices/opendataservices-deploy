{% from 'lib.sls' import createuser, apache %}

include:
  - apache
  - letsencrypt


{% set user="datatig" %}

{{ createuser(user) }}

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

# Build now
build-{{ user }}-real-staticsite-demos:
  cmd.run:
    - name: "git pull && source .ve/bin/activate && pip3 install -U git+https://github.com/DataTig/DataTig.git@main#egg=datatig && ./build.sh"
    - user: "{{ user }}"
    - cwd: /home/{{ user }}/real-staticsite-demos
    - require:
      - virtualenv: /home/{{ user }}/real-staticsite-demos/.ve/

# Cron for building regularly
cd /home/{{ user }}/real-staticsite-demos; git pull; source ve/bin/activate; pip3 install -U git+https://github.com/DataTig/DataTig.git@main#egg=datatig; ./build.sh:
  cron.present:
    - identifier: DATATIG_REAL_STATIC_SITE_DEMOS
    - user: {{ user }}
    - minute: 0
    - hour: 4

# Serve static website
{{ apache(user+'-real-staticsite-demos.conf',
    name=user+'-real-staticsite-demos.conf',
    servername='datatig-rsd.' + grains.fqdn,
    https='force') }}
