# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core

  # LIVE

  'live2':
    - icinga2-satellite

  'live3':
    - icinga2-satellite
    - prometheus-client-apache
    - os4d

  'live4':
    - prometheus-client-apache
    - opendataservices-website
    - icinga2-satellite

  'cove*live*':
    - cove
    - icinga2-satellite

  'cove-live-iati':
    - prometheus-client-apache

  'cove-live-bods':
    - prometheus-client-apache

  'cove-360-live':
    - prometheus-client-apache

  'grantnav-live*':
    - grantnav
    - icinga2-satellite
    - prometheus-client-apache

  'data-360-live':
    - registry360
    - icinga2-satellite
    - prometheus-client-apache

  'org-ids':
    - org-ids
    - prometheus-client-apache
    - icinga2-satellite

  'bods':
    - prometheus-client-apache
    - icinga2-satellite

  # STAGING

  'cove-staging':
    - cove
    - icinga2-satellite

  # DEVELOPMENT

  'dev3':
    - opendataservices-website
    - temp
    - icinga2-satellite

  'dev4':
    - org-ids
    - icinga2-satellite
    - prometheus-client-apache
    - os4d
    - registry360

  'cove*dev*':
    - cove
    - icinga2-satellite
    - prometheus-client-apache

  'cove-dev*':
     - cove_dev_redirects

  'grantnav-dev*':
    - grantnav-es7
    - icinga2-satellite
    - prometheus-client-apache

  'pwyf-dev':
    - pwyf-tracker
#    - icinga2-satellite

  'iati-misc':
    - iati-misc
    - prometheus-client-apache
#    - icinga2-satellite


  # MONITORING

  'mon-2':
    - icinga2-master
    - piwik

  'mon-3':
    - icinga2-master
    - piwik

  'mon-4':
    - prometheus-server
    - prometheus-client-apache

  # OTHERS

  'snapshotter':
    - icinga2-satellite
    - prometheus-client-apache

  'backups':
    - icinga2-satellite
    - prometheus-client-apache
    - backups

