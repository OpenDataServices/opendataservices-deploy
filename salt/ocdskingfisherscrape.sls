{% from 'lib.sls' import createuser %}


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


