# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core
  # Our main live server
  'live1':
    - opencontracting
    - opendataservices-website
    - icinga2-satellite

  'live2':
    - ocds-docs-live
    - threesixtygiving_data
    - icinga2-satellite

  'cove-live':
    - cove
    - icinga2-satellite

  'cove-live-ocds':
    - cove
    - icinga2-satellite

  # A development server
  'dev1':
    - opencontracting
    - cove
    - opendataservices-website
    - icinga2-satellite

  # Our monitoring server
  'mon*':
    - icinga2-master
    - piwik
    #- logserver

  'dev2':
    - icinga2-satellite
    - dkan-script

  'dev3':
    - ocds-docs-dev
    - icinga2-satellite

  'grantnav-dev':
    - grantnav-dev
    - icinga2-satellite

  'snapshotter':
    - icinga2-satellite

  'backups':
    - icinga2-satellite
    - backups
