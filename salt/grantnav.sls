# To reload this from scratch, do
# rm -r /etc/apache2/sites-*/* /etc/uwsgi/apps-*/ /home/grantnav/grantnav* /tmp/*.sock /etc/apache2/htpasswd*
# and then run highstate.

{% from 'lib.sls' import createuser, apache, uwsgi %}

{{ createuser(pillar.grantnav.user) }}

include:
  - core
  - elasticsearch7
  - apache
  - uwsgi

grantnav-deps:
    pkg.installed:
      - pkgs:
        - libapache2-mod-proxy-uwsgi
        - python-pip
        - python-virtualenv
        - uwsgi-plugin-python3
        - gettext
      - watch_in:
        - service: apache2
        - service: uwsgi

    apache_module.enabled:
      - name: proxy proxy_uwsgi ssl
      - watch_in:
        - service: apache2

##### Grantnav

/home/{{ pillar.grantnav.user }}/grantnav:
  git.latest:
    - name: {{ pillar.grantnav.git_url }}
    - rev: {{ pillar.grantnav.branch }}
    - target: /home/{{ pillar.grantnav.user }}/grantnav
    - user: {{ pillar.grantnav.user }}
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git


##### Install python deps in virtualenvs

/home/{{ pillar.grantnav.user }}/grantnav/.ve:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ pillar.grantnav.user }}
    - system_site_packages: False
    - requirements: /home/{{ pillar.grantnav.user }}/grantnav/requirements.txt
    - require:
      - git: /home/{{ pillar.grantnav.user }}/grantnav

##### Install django app 
{% set djangodir='/home/'+pillar.grantnav.user+'/grantnav/' %}

{{ pillar.grantnav.static_dir }}:
  file.directory:
    - user: grantnav
    - group: www-data
    - mode: 755
    - makedirs: True

migrate-database:
  cmd.run:
    - name: source {{ djangodir }}/.ve/bin/activate; python manage.py migrate --noinput
    - runas: {{ pillar.grantnav.user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: /home/{{ pillar.grantnav.user }}/grantnav/.ve
    - onchanges:
      - git: {{ pillar.grantnav.git_url }}

collectstatic:
  cmd.run:
    - name: source {{ djangodir }}/.ve/bin/activate; python manage.py collectstatic -v 3  --noinput
    - runas: {{ pillar.grantnav.user }}
    - cwd: {{ djangodir }}
    - require:
      - virtualenv: /home/{{ pillar.grantnav.user }}/grantnav/.ve
      - file: {{ pillar.grantnav.static_dir }}
    - onchanges:
      - git: {{ pillar.grantnav.git_url }}

update_static_dir:
  cmd.run:
    - name: cp -r {{ djangodir }}/static/* {{ pillar.grantnav.static_dir }}; chown -R www-data.www-data {{ pillar.grantnav.static_dir }}
    - require:
      - collectstatic
    - onchanges:
      - git: {{ pillar.grantnav.git_url }}

##### Datastore data fetcher


/home/{{ pillar.grantnav.user }}/logs:
  file.directory:
    - user: grantnav
    - group: grantnav
    - mode: 700
    - makedirs: True

/home/{{ pillar.grantnav.user }}/poll_datastore.py:
  file.managed:
    - source: https://raw.githubusercontent.com/ThreeSixtyGiving/datastore/master/tools/poll_datastore.py
    - source_hash: sha256=5056492bec6a4027a023f897dc773340df76dfc9a17c60cd4c1c2b8c06b89540
    - user: {{ pillar.grantnav.user }}
    - mode: 755

/home/{{ pillar.grantnav.user }}/reload_latest_daily.sh:
  file.managed:
    - source: salt://grantnav/reload_latest_daily.sh
    - template: jinja
    - context:
       user: {{ pillar.grantnav.user }}
       djangodir: {{ djangodir }}
    - mode: 755

/home/{{ pillar.grantnav.user }}/poll_datastore.sh:
  file.managed:
    - source: salt://grantnav/poll_datastore.sh
    - template: jinja
    - context:
       user: {{ pillar.grantnav.user }}
       datastore_user: {{ pillar.grantnav.datastore_user }}
       datastore_password: {{ pillar.grantnav.datastore_password }}
       datastore_url: {{ pillar.grantnav.datastore_url }}
    - mode: 755

datastore_poll:
    cron.present:
      - name: bash /home/{{ pillar.grantnav.user }}/poll_datastore.sh
      - user: {{ pillar.grantnav.user }}
      - minute: '*/5'
      - require:
        - file: /home/{{ pillar.grantnav.user }}/poll_datastore.sh

##### Scheduled backup snapshots of index

snap_weekly:
   cron.present:
     - name: . {{ djangodir }}/.ve/bin/activate; export SOURCE_INDEX=`cat /home/{{ pillar.grantnav.user }}/es_index`; python3 {{ djangodir }}/dataload/copy_es_index.py $SOURCE_INDEX latest_weekly; date > /home/{{ pillar.grantnav.user }}/latest_weekly_snapshot.log
     - user: {{ pillar.grantnav.user }}
     - minute: 0
     - hour: 4
     - dayweek: 0

snap_monthly:
   cron.present:
     - name: . {{ djangodir }}/.ve/bin/activate; export SOURCE_INDEX=`cat /home/{{ pillar.grantnav.user }}/es_index`; python3 {{ djangodir }}/dataload/copy_es_index.py $SOURCE_INDEX latest_monthly; date > /home/{{ pillar.grantnav.user }}/latest_monthly_snapshot.log
     - user: {{ pillar.grantnav.user }}
     - minute: 0
     - hour: 5
     - daymonth: 1

##### Apache

{{

apache(
  'grantnav.conf',
  name='grantnav.conf',
  servername=grains.fqdn,
  serveraliases=pillar.grantnav.serveraliases,
  https='no'
)

}}

{{

uwsgi('grantnav.ini', name='grantnav.ini')

}}

##### Elasticsearch config

/etc/elasticsearch/elasticsearch.yml:
  file.append:
    - text: |
        cluster.name: {{ grains.host }}
    - require:
      - pkg: elasticsearch-base



##### threesixtygiving.org SSL cert

/etc/apache2/ssl:
  file.directory:
    - file_mode: 700
    - dir_mode: 700
    - user: www-data
    - group: www-data

/etc/apache2/ssl/ssl.2019.cert:
  file.managed:
    - source: salt://private/grantnav/ssl.2019.cert
    - user: www-data
    - group: www-data
    - mode: 700
    - require:
      - file: /etc/apache2/ssl

/etc/apache2/ssl/ssl.2019.key:
  file.managed:
    - source: salt://private/grantnav/ssl.2019.key
    - user: www-data
    - group: www-data
    - mode: 700
    - require:
      - file: /etc/apache2/ssl

/etc/apache2/ssl/ssl.2019.intermediate:
  file.managed:
    - source: salt://private/grantnav/ssl.2019.intermediate
    - user: www-data
    - group: www-data
    - mode: 700
    - require:
      - file: /etc/apache2/ssl


###### SOCKS Proxy user for Datastore #######
socks_proxy_user_setup:
  user.present:
    - name: datagetter_proxy
    - home: /home/datagetter_proxy
    - shell: /usr/sbin/nologin


/home/datagetter_proxy/.ssh/authorized_keys:
  file.managed:
    - source: salt://private/grantnav/datastore_datagetter_ssh_key.pub
    - makedirs: True
    - user: datagetter_proxy
    - group: datagetter_proxy
    - mode: 700
    - require:
      - user: socks_proxy_user_setup

#############################################
