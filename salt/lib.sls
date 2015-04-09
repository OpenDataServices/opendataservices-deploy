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
    - watch_in: apache2

# Create a symlink from sites-enabled to enable the config
/etc/apache2/sites-enabled/{{ conffile }}:
  file.symlink:
    - target: /etc/apache2/sites-available/{{ conffile }}
    - require:
      - file: /etc/apache2/sites-available/{{ conffile }}
    - makedirs: True
    - watch_in: apache2
{% endmacro %}
