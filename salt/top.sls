# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core

  # LIVE

  'live3':
    - icinga2-satellite
    - prometheus-client-apache
    - os4d

  'live4':
    - prometheus-client-apache
    - opendataservices-website
    - cove-opendataservices-coop
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

  'grantnav-live-teal':
    - grantnav
    - icinga2-satellite
    - prometheus-client-apache

  'grantnav-live-orange':
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

  'datastore-360-live':
    - icinga2-satellite
    - 360-datastore
    - prometheus-client-apache

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
    - prometheus-client-apache
#    - icinga2-satellite
#
  'pwyf-tracker-*':
    - pwyf-tracker-original
    - prometheus-client-apache

  'pwyf-dqt-*':
    - pwyf-dqt
    - prometheus-client-apache

  'pwyf-merger':
    - pwyf-merger


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

  # Prometheus on mon-4 is using IP white-listing for sending emails - if we move server/IP that will need attention.
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

