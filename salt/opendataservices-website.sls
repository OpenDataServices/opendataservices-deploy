# To deploy this state you will also need to 
{% set user = 'opendataservices' %}

{{ user }}-user-exists:
  user.present:
    - name: {{ user }}
    - home: /home/{{ user }}

git:
  pkg.installed


{% for file in ['id_rsa', 'id_rsa.pub'] %}
/home/{{ user }}/.ssh/{{ file }}:
  file.managed:
    - source: salt://ssh/{{ file }}    
{% endfor %}

opendataservices.plan.io:
  ssh_known_hosts:
    - present
    - user: {{ user }}
    - enc: rsa
    - fingerprint: 77:d1:54:d7:33:7e:38:43:40:70:ca:2d:3a:24:05:22

git@opendataservices.plan.io:standardsupport-civic-data-standards.website.git:
  git.latest:
    - rev: live
    - target: /home/{{ user }}/website/
    - user: {{ user }}
    - submodules: True
    - require:
      - pkg: git



## Apache

{% set conffile = 'opendataservices-website.conf' %}
/etc/apache2/sites-available/{{ conffile }}:
  file.managed:
    - source: salt://apache/{{ conffile }}
    - template: jinja


/etc/apache2/sites-enabled/{{ conffile }}:
    file.symlink:
        - target: /etc/apache2/sites-available/{{ conffile }}

apache2:
  pkg.installed:
    -
  service:
    - running
    - enable: True
    - reload: True
    - watch:
      - file: /etc/apache2/sites-available/{{ conffile}}
