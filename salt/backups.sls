{% from 'lib.sls' import createuser, apache %}

{% set user = 'automated' %}
{{ createuser(user) }}

acl:
  pkg.installed

# Ensure all home directories are only readable by their users (and root)
chmod og-rwx /home/*; setfacl -d -m g::--- /home/*; setfacl -d -m o::--- /home/*:
  cmd.run
