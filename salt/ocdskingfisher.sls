{% from 'lib.sls' import createuser %}

# Set up the server

/etc/motd:
  file.managed:
    - source: salt://system/ocdskingfisher_motd


