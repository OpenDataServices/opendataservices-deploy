{% from 'lib.sls' import createuser, apache %}

include:
  - apache

ocdskingfisherscrape-prerequisites  :
  apache_module.enabled:
    - name: proxy proxy_http
    - watch_in:
      - service: apache2

{% set user = 'ocdskfs' %}
{{ createuser(user) }}

{% set giturl = 'https://github.com/open-contracting/kingfisher-scrape.git' %}

{% set userdir = '/home/' + user %}
{% set ocdskingfisherdir = userdir + '/ocdskingfisherscrape/' %}

{{ giturl }}{{ ocdskingfisherdir }}:
  git.latest:
    - name: {{ giturl }}
    - user: {{ user }}
    - force_fetch: True
    - force_reset: True
    - branch: master-scrapy ### This is temporary - it will soon be set to master and not changed
    - rev: master-scrapy ### This is temporary - it will soon be set to master and not changed
    - target: {{ ocdskingfisherdir }}
    - require:
      - pkg: git

{{ ocdskingfisherdir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ ocdskingfisherdir }}
    - requirements: {{ ocdskingfisherdir }}requirements.txt
    - require:
      - git: {{ giturl }}{{ ocdskingfisherdir }}


{% set scrapyddir = userdir + '/scrapyd/' %}

{{ scrapyddir }}:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}requirements.txt:
  file.managed:
    - source: salt://ocdskingfisherscrape/scrapyd-requirements.txt
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0444
    - require:
      - file: {{ scrapyddir }}

{{ scrapyddir }}.ve/:
  virtualenv.managed:
    - python: /usr/bin/python3
    - user: {{ user }}
    - system_site_packages: False
    - cwd: {{ scrapyddir }}
    - requirements: {{ scrapyddir }}requirements.txt
    - require:
      - file: {{ scrapyddir }}requirements.txt

{{ scrapyddir }}dbs:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}eggs:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}logs:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

{{ scrapyddir }}items:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    - group: {{ user }}

/home/{{ user }}/.scrapyd.conf:
  file.managed:
    - source: salt://ocdskingfisherscrape/scrapyd.ini
    - template: jinja
    - context:
        scrapyddir: {{ scrapyddir }}

/home/{{ user }}/runscrapyd.sh:
  file.managed:
    - source: salt://ocdskingfisherscrape/runscrapyd.sh
    - user: {{ user }}
    - group: {{ user }}
    - mode: 0744
    - template: jinja
    - context:
        scrapyddir: {{ scrapyddir }}

kfs-apache-password:
  cmd.run:
    - name: rm /home/{{ user }}/htpasswd ; htpasswd -c -b /home/{{ user }}/htpasswd scrape {{ pillar.ocdskingfisherscrape.web.password }}
    - runas: {{ user }}
    - cwd: /home/{{ user }}

{{ apache('ocdskingfisherscrape.conf',
    name='ocdskingfisherpscrape.conf',
    servername='ocdskingfisher-dev') }}

