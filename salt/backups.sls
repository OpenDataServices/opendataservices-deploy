{% from 'lib.sls' import createuser, apache %}


acl:
  pkg.installed


{% for user in ['archive','nrgi','pantheon','planio','threesixtygiving_data'] %}

{{ createuser(user) }}

# Ensure home directory is only readable by their users (and root)
# We get errors because some folders are empty or because you can't set default acls on files; ignore
chmod og-rwx /home/{{ user }}/* || true:
  cmd.run

setfacl -d -m g::--- /home/{{ user }}/* || true:
  cmd.run

setfacl -d -m o::--- /home/{{ user }}/* || true:
  cmd.run

{% endfor %}

