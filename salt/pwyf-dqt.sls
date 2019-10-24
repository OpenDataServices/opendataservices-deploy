## Publish What You Fund Data Quality Tester
## https://github.com/pwyf/data-quality-tester

{% from 'lib.sls' import createuser, apache, uwsgi %}

##### System install

include:
  - core
  - apache
  - uwsgi
#   - letsencrypt

# uWSGI from data-quality-tester > requirements.txt has a C
# extension not sure if this is needed given we install the pkg
# uwsgi-plugin-python3 but it is in the current requirements so we
# need to make sure it is installable

pwyf-dqt-deps:
  pkg.installed:
    - pkgs:
      - virtualenv
      - libapache2-mod-proxy-uwsgi
      - uwsgi-plugin-python3
      - redis-server
      # See uWSGI comment ^
      - build-essential
      - python3-dev
    - watch_in:
      - service: apache2
      - service: uwsgi

  apache_module.enabled:
    - name: proxy proxy_uwsgi
    - watch_in:
      - service: apache2
      - service: uwsgi

# redis should start up after being installed but this will verify
# If redis fails with redis-server.service: Can't open PID file this may
# be due to bind ::1 in the default redis config
redis-server:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - reload: True

{{ createuser(pillar.pwyf_dqt.user) }}

##### Git checkout 

/home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}:
  git.latest:
    - name: {{ pillar.pwyf_dqt.git_url }}
    - rev: {{ pillar.pwyf_dqt.branch }}
    - user: {{ pillar.pwyf_dqt.user }}
    - target: /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}
    - force_fetch: True
    - force_reset: True
    - submodules: True
    - require:
      - pkg: git

##### Install python deps in virtualenv

/home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/.ve:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ pillar.pwyf_dqt.user }}
    - system_site_packages: False
    - requirements: /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/requirements.txt
    - require:
      - git: /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}

##### Flask app setup

setup_dqt:
  cmd.run:
    - runas: {{ pillar.pwyf_dqt.user }}
    - env:
      - FLASK_APP: 'DataQualityTester/__init__.py'
    - cwd: /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/
    - name: source ./.ve/bin/activate; cp config.py.tmpl config.py; flask db upgrade; flask assets build

## Flask config
/home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/config.py:
 file.append:
    - text:
      - "    SQLALCHEMY_DATABASE_URI='sqlite:////home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/db.sqlite3'"
      - "    SECRET_KEY='{{ pillar.pwyf_dqt_private.secret_key }}'"
    - require:
      - setup_dqt



{{ pillar.pwyf_dqt.static_dir }}:
  file.directory:
    - user: {{ pillar.pwyf_dqt.user }}
    - group: www-data
    - mode: 755
    - makedirs: True

setup_dqt_assets:
  cmd.run:
    - name: cp -r /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/DataQualityTester/static/* {{ pillar.pwyf_dqt.static_dir }} ; chown -R www-data.www-data {{ pillar.pwyf_dqt.static_dir }}
    - require:
      - file: {{ pillar.pwyf_dqt.static_dir }}

##### Celery setup

/etc/systemd/system/pwyf_dqt_celery.service:
  file.managed:
    - source: salt://systemd/pwyf_dqt_celery.service
    - template: jinja
    - context:
      ve_bin: /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/.ve/bin/activate
      user: {{ pillar.pwyf_dqt.user }}


/etc/default/pwyf_dqt_celery:
  file.managed:
    - source: salt://etc-default/pwyf_dqt_celery
    - template: jinja
    - context:
      user: {{ pillar.pwyf_dqt.user }}
      nodes: {{ pillar.pwyf_dqt.celery_nodes }}
      celery_path: /home/{{ pillar.pwyf_dqt.user }}/{{ pillar.pwyf_dqt.checkout_dir }}/.ve/bin/celery

/var/log/pwyf_dqt_celery:
  file.directory:
    - makedirs: True
    - user: {{ pillar.pwyf_dqt.user }}
    - group: {{ pillar.pwyf_dqt.user }}


/var/run/pwyf_dqt_celery:
  file.directory:
    - makedirs: True
    - user: {{ pillar.pwyf_dqt.user }}
    - group: {{ pillar.pwyf_dqt.user }}

pwyf_dqt_celery:
  service:
    - running
    - enable: True
    - reload: True
    - require:
      - /var/run/pwyf_dqt_celery

##### Cron job for clean ups

clean_up_cron:
  cron.present:
    - name: cd /home/{{ pillar.pwyf_dqt.user}}/{{ pillar.pwyf_dqt.checkout_dir }} ; source ./.ve/bin/activate ; FLASK_APP=DataQualityTester/__init__.py flask flush-data
    - user: {{ pillar.pwyf_dqt.user }}
    - minute: 0
    - hour: 0


##### Webserver setup

{% set extracontext %}
user: {{ pillar.pwyf_dqt.user }}
checkout_dir: {{ pillar.pwyf_dqt.checkout_dir }}
static_dir: {{ pillar.pwyf_dqt.static_dir }}
{% endset %}

{{
apache(
  'pwyf-dqt.conf',
  name='pwyf-dqt.conf',
  servername=pillar.pwyf_dqt.servername,
  serveraliases=[ pillar.pwyf_dqt.servername+'.'+grains.fqdn ],
  extracontext=extracontext,
  https='no'
)
}}

{{
uwsgi('pwyf-dqt.ini', name='pwyf-dqt.ini', extracontext=extracontext )
}}
