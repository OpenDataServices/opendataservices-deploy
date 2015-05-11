# This file defines various common macros.




# Create a user
# Our deployment policy is to run as much as possible as unpriviledged users.
# Ideally each piece of work we do (which probably maps to a separate salt
# forumula) should have its own user defined.
# Therefore, most of our main salt formulas will begin by defining a user.
{% macro createuser(user) %}

{{ user }}-user-exists:
  user.present:
    - name: {{ user }}
    - home: /home/{{ user }}
    - order: 1

{% endmacro %}





# Install the named conf file in the apache dir onto the server.
{% macro apache(conffile) %}
# Render the file with jinja and place it in sites-available
/etc/apache2/sites-available/{{ conffile }}:
  file.managed:
    - source: salt://apache/{{ conffile }}
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: apache2
    - context:
      {% if 'banner_message' in pillar %}
      banner: |
        # Inflate and deflate here to ensure that the message it not
        # compressed when we do the substitution, but is afterwards.
        # I think this may be adding some extra overhead, but for our
        # dev site this shouldn't be noticeable.
        AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE text/html
        Substitute "s|<body([^>]*)>|<body$1><div style=\"background-color:red; color: black; width: 100%; text-align: center; font-weight: bold; position: fixed; right: 0; left: 0; z-index: 1031\">{{ pillar.banner_message }}</div>|i"
      {% else %}
      banner: ''
      {% endif %}

# Create a symlink from sites-enabled to enable the config
/etc/apache2/sites-enabled/{{ conffile }}:
  file.symlink:
    - target: /etc/apache2/sites-available/{{ conffile }}
    - require:
      - file: /etc/apache2/sites-available/{{ conffile }}
    - makedirs: True
    - watch_in:
      - service: apache2
{% endmacro %}

{% macro uwsgi(conffile) %}
# Render the file with jinja and place it in apps-available
/etc/uwsgi/apps-available/{{ conffile }}:
  file.managed:
    - source: salt://uwsgi/{{ conffile }}
    - template: jinja
    - makedirs: True
    - watch_in:
      - service: uwsgi

# Create a symlink from apps-enabled to enable the config
/etc/uwsgi/apps-enabled/{{ conffile }}:
  file.symlink:
    - target: /etc/uwsgi/apps-available/{{ conffile }}
    - require:
      - file: /etc/uwsgi/apps-available/{{ conffile }}
    - makedirs: True
    - watch_in:
      - service: uwsgi
{% endmacro %}




{% macro planio_keys(user) %}
# Add a public and private key to this server, so that it can authenticate
# against plan.io
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
