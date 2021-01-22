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
    - org-ids-datatig

  'cove*live*':
    - cove
    - icinga2-satellite

  'cove-live-iati':
    - prometheus-client-apache

  'cove-live-bods':
    - prometheus-client-apache

  'org-ids':
    - org-ids
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

  'dev5':
    - prometheus-client-apache
    - json-data-ferret

  'cove*dev*':
    - cove
    - icinga2-satellite
    - prometheus-client-apache

  'cove-dev*':
     - cove_dev_redirects


  'iati-misc':
    - iati-misc
    - prometheus-client-apache
#    - icinga2-satellite

  'oroi*':
    # Mostly not managed with salt, see the roster for more information.
    - docker-workarounds

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

  'dokku*':
    - dokku

