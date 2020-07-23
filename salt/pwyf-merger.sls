## Publish What You Fund Data Quality Tester
## https://github.com/pwyf/data-quality-tester

{% from 'lib.sls' import createuser, apache, uwsgi %}

##### System install

include:
  - core
  - apache
  - uwsgi
  - letsencrypt

# uWSGI from data-quality-tester > requirements.txt has a C
# extension not sure if this is needed given we install the pkg
# uwsgi-plugin-python3 but it is in the current requirements so we
# need to make sure it is installable

pwyf-merger-deps:
  pkg.installed:
    - pkgs:
      - cron
      - virtualenv
      - libapache2-mod-proxy-uwsgi
      - uwsgi-plugin-python3
      # See uWSGI comment ^
      - build-essential
      - python3-dev
      - python-pip
    - watch_in:
      - service: apache2
      - service: uwsgi

  apache_module.enabled:
    - name: proxy proxy_uwsgi
    - watch_in:
      - service: apache2
      - service: uwsgi

{{ createuser(pillar.pwyf_merger.user) }}

##### Git checkout

/home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}:
  git.latest:
    - name: {{ pillar.pwyf_merger.git_url }}
    - rev: {{ pillar.pwyf_merger.branch }}
    - user: {{ pillar.pwyf_merger.user }}
    - target: /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}
    - force_fetch: True
    - force_reset: True
    - submodules: True
    - require:
      - pkg: git

##### Install python deps in virtualenv

/home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}/.ve:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ pillar.pwyf_merger.user }}
    - system_site_packages: False
    - requirements: /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}/requirements.txt
    - require:
      - git: /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}

##### Flask app setup
## Flask config

default_config:
  file.copy:
    - source: /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}/config.py.tmpl
    - name: /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}/default_config.py

new_config:
  file.managed:
    - name: /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}/config.py
    - source: salt://pwyf-merger/config.py
    - template: jinja
    - context:
      secret_key: {{ pillar.pwyf_merger_private.secret_key }}
      input_dir: {{ pillar.pwyf_merger.input_dir }}
      output_dir : {{ pillar.pwyf_merger.output_dir }}
    - require:
      - default_config

{{ pillar.pwyf_merger.static_dir }}:
  file.directory:
    - user: {{ pillar.pwyf_merger.user }}
    - group: www-data
    - mode: 755
    - makedirs: True

setup_merger_assets:
  cmd.run:
    - name: cp -r /home/{{ pillar.pwyf_merger.user }}/{{ pillar.pwyf_merger.checkout_dir }}/ActivityMerger/static/* {{ pillar.pwyf_merger.static_dir }} ; chown -R www-data.www-data {{ pillar.pwyf_merger.static_dir }}
    - require:
      - file: {{ pillar.pwyf_merger.static_dir }}

{{ pillar.pwyf_merger.input_dir }}:
  file.directory:
    - user: {{ pillar.pwyf_merger.user }}
    - group: www-data
    - mode: 755
    - makedirs: True

{{ pillar.pwyf_merger.output_dir }}:
  file.directory:
    - user: {{ pillar.pwyf_merger.user }}
    - group: www-data
    - mode: 755
    - makedirs: True

clean_up_cron:
  cron.present:
    - name: cd /home/{{ pillar.pwyf_merger.user}}/{{ pillar.pwyf_merger.checkout_dir }} ; . ./.ve/bin/activate ; FLASK_APP=ActivityMerger/__init__.py flask flush-data
    - user: {{ pillar.pwyf_merger.user }}
    - minute: 0
    - hour: 0

##### Webserver setup

{% set extracontext %}
user: {{ pillar.pwyf_merger.user }}
checkout_dir: {{ pillar.pwyf_merger.checkout_dir }}
static_dir: {{ pillar.pwyf_merger.static_dir }}
input_dir: {{ pillar.pwyf_merger.input_dir }}
output_dir: {{ pillar.pwyf_merger.output_dir }}
{% endset %}

{{
apache(
  'pwyf-merger.conf',
  name='pwyf-merger.conf',
  servername=pillar.pwyf_merger.servername,
  serveraliases=[  ],
  extracontext=extracontext,
  https='yes'
)
}}

{{
uwsgi('pwyf-merger.ini', name='pwyf-merger.ini', extracontext=extracontext )
}}
