# This file defines various common macros.


#-----------------------------------------------------------------------
# createuser
#
# Our deployment policy is to run as much as possible as unprivileged users.
# Ideally each piece of work we do (which probably maps to a separate salt
# forumula) should have its own user defined.
# Therefore, most of our main salt formulas will begin by defining a user.
#-----------------------------------------------------------------------

{% macro createuser(user) %}

{{ user }}_user_exists:
  user.present:
    - name: {{ user }}
    - home: /home/{{ user }}
    - order: 1

{% if user+'_authorized_keys' in pillar %}

# Install authorized SSH public keys.  Keys will be installed from both
# pillar.<user>_authorized_keys and pillar.authorized_keys

{{ user }}_user_ssh_dir:
  file.directory:
    - name: /home/{{ user }}/.ssh
    - user: {{ user }}
    - group: users
    - mode: 700
    - require:
      - user: {{ user }}_user_exists

{{ user }}_user_ssh_userkeys:
  file.managed:
    - name: /home/{{ user }}/.ssh/authorized_keys
    - contents_pillar: {{ user }}_authorized_keys
    - user: {{ user }}
    - group: users
    - mode: 644
    - require:
      - file: user_ssh_dir

{{ user }}_user_ssh_rootkeys:
  file.append:
    - name: /home/{{ user }}/.ssh/authorized_keys
    - text: {{ salt['pillar.get']('authorized_keys') | yaml_encode }}
    - require:
      - file: user_ssh_userkeys

{% endif %}

{% endmacro %}



#-----------------------------------------------------------------------
# letsencrypt
# Automatically obtain and install a Letsencrypt certificate
#-----------------------------------------------------------------------

{% macro letsencrypt(servername, serveraliases) %}

{% set domainargs="-d "+servername %}
{% for alias in serveraliases %}
{% set domainargs=domainargs+" -d "+alias %}
{% endfor %}

{{ servername }}_acquire_certs:
  cmd.run:
    - name: letsencrypt certonly --non-interactive --no-self-upgrade --expand --email code@opendataservices.coop --agree-tos --webroot --webroot-path /var/www/html/ {{ domainargs }}
    - creates:
      - /etc/letsencrypt/live/{{ servername }}/cert.pem
      - /etc/letsencrypt/live/{{ servername }}/chain.pem
      - /etc/letsencrypt/live/{{ servername }}/fullchain.pem
      - /etc/letsencrypt/live/{{ servername }}/privkey.pem
    - require:
      - pkg: letsencrypt

{% endmacro %}



#-----------------------------------------------------------------------
# apache
# Install the named conf file in the apache dir onto the server.
#-----------------------------------------------------------------------

{% macro apache(conffile, name='', extracontext='', socket_name='', servername='', serveraliases=[], https='') %}

{% if name == '' %}
{% set name=conffile %}
{% endif %}
{% if servername == '' %}
{% set servername=grains.fqdn %}
{% endif %}

{% if https == 'yes' or https == 'force' %}

{{ letsencrypt(servername, serveraliases) }}

# https-enabled config has two files: the main .conf file is just
# boilerplate from _common.conf, the service-specific config is in an
# Apache-included file <name>.conf.include.
#   Note 1, the include does not get linked into sites-enabled.
#   Note 2, ideally we would use a Jinja include to create a proper
#           standalone conf file, but that doesn't work in salt-ssh.

/etc/apache2/sites-available/{{ name }}:
  file.managed:
    - source: salt://apache/_common.conf
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        socket_name: {{ socket_name }}
        includefile: {{ conffile }}.include
        servername: {{ servername }}
        serveraliases: {{ serveraliases }}
        https: "{{ https }}"
        {{ extracontext | indent(8) }}

/etc/apache2/sites-available/{{ name }}.include:
  file.managed:
    - source: salt://apache/{{ conffile }}.include
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        socket_name: {{ socket_name }}
        https: "{{ https }}"
      {% if 'banner_message' in pillar %}
        banner: |
          # Inflate and deflate here to ensure that the message is not
          # compressed when we do the substitution, but is afterwards.
          # I think this may be adding some extra overhead, but for our
          # dev site this shouldn't be noticeable.
          AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE text/html
          Substitute "s|<body([^>]*)>|<body$1><div style=\"background-color:red; color: black; width: 100%; text-align: center; font-weight: bold; position: fixed; right: 0; left: 0; z-index: 1031\">{{ pillar.banner_message }}</div>|i"
        {% else %}
        banner: ''
      {% endif %}
        {{ extracontext | indent(8) }}

{% else %}

# Render the config files (common and include) with jinja and place them in sites-available
/etc/apache2/sites-available/{{ name }}:
  file.managed:
    - source: salt://apache/{{ conffile }}
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
        socket_name: {{ socket_name }}
        servername: {{ servername }}
        serveraliases: {{ serveraliases }}
        https: "{{ https }}"
      {% if 'banner_message' in pillar %}
        banner: |
          # Inflate and deflate here to ensure that the message is not
          # compressed when we do the substitution, but is afterwards.
          # I think this may be adding some extra overhead, but for our
          # dev site this shouldn't be noticeable.
          AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE text/html
          Substitute "s|<body([^>]*)>|<body$1><div style=\"background-color:red; color: black; width: 100%; text-align: center; font-weight: bold; position: fixed; right: 0; left: 0; z-index: 1031\">{{ pillar.banner_message }}</div>|i"
      {% else %}
        banner: ''
      {% endif %}
        {{ extracontext | indent(8) }}

{% endif %}

# Create a symlink from sites-enabled to enable the config
/etc/apache2/sites-enabled/{{ name }}:
  file.symlink:
    - target: /etc/apache2/sites-available/{{ name }}
    - require:
      - file: /etc/apache2/sites-available/{{ name }}
    - makedirs: True
    - watch_in:
      - service: apache2
{% endmacro %}



#-----------------------------------------------------------------------
# uwsgi
#-----------------------------------------------------------------------

{% macro uwsgi(conffile, name, djangodir, port='', socket_name='', extracontext='') %}
# Render the file with jinja and place it in apps-available
/etc/uwsgi/apps-available/{{ name }}:
  file.managed:
    - source: salt://uwsgi/{{ conffile }}
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: uwsgi
    - context:
        socket_name: {{ socket_name }}
        djangodir: {{ djangodir }}
        port: {{ port }}
        {{ extracontext | indent(8) }}

# Create a symlink from apps-enabled to enable the config
/etc/uwsgi/apps-enabled/{{ name }}:
  file.symlink:
    - target: /etc/uwsgi/apps-available/{{ name }}
    - require:
      - file: /etc/uwsgi/apps-available/{{ name }}
    - makedirs: True
    - watch_in:
      - service: uwsgi

# Add a fail2ban jail for this uwsgi instance
# /etc/fail2ban/jail.d/uwsgi-{{ name }}.conf:
#   file.managed:
#     - source: salt://fail2ban/jail.d/uwsgi.conf
#     - template: jinja
#     - makedirs: True
#     - watch_in:
#       - service: fail2ban
#     - context:
#         name: {{ name }}
#         port: {{ port }}

{% endmacro %}



#-----------------------------------------------------------------------
# planio_keys
# Add a public and private key to this server, so that it can authenticate
# against plan.io
#-----------------------------------------------------------------------

{% macro planio_keys(user) %}
{% for file in ['id_rsa', 'id_rsa.pub'] %}
/home/{{ user }}/.ssh/{{ file }}:
  file.managed:
    - contents_pillar: {{ file.replace('.', '_') }}
    - makedirs: True
{% endfor %}

# Ensure that we recognise the fingerprint of the plan.io git server
{{ user }}-opendataservices.plan.io:
  ssh_known_hosts:
    - name: opendataservices.plan.io
    - present
    - user: {{ user }}
    - enc: rsa
    - fingerprint: 77:d1:54:d7:33:7e:38:43:40:70:ca:2d:3a:24:05:22
{% endmacro %}
