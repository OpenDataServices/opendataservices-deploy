# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core

  # LIVE

  'live2':
    - ocds-docs-live
    - ocds-legacy
    - threesixtygiving_data
    - opendataservices-website
    - icinga2-satellite

  'cove-live':
    - cove
    - icinga2-satellite

  'cove-live-ocds':
    - cove
    - icinga2-satellite

  # DEVELOPMENT

  'dev2':
    - icinga2-satellite
    - dkan-script

  'dev3':
    - ocds-docs-dev
    - opendataservices-website
    - icinga2-satellite

  'cove-dev':
    - cove
    - icinga2-satellite

  'grantnav-dev':
    - grantnav-dev
    - icinga2-satellite

  # MONITORING

  'mon*':
    - icinga2-master
    - piwik

  # OTHERS

  'snapshotter':
    - icinga2-satellite

  'backups':
    - icinga2-satellite
    - backups
