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
    # This is being moved to live5
    - os4d

  'live4':
    - prometheus-client-apache
    - opendataservices-website
    - cove-opendataservices-coop
    - icinga2-satellite

  'live5':
    - prometheus-client-apache
    - os4d
    - org-ids

  'cove*live*':
    - cove
    - icinga2-satellite

  'cove-live-iati':
    - prometheus-client-apache

  'cove-live-iati-2':
    - prometheus-client-apache

  'cove-live-bods':
    - prometheus-client-apache

  'org-ids':
    # This is being moved to live5
    - org-ids
    - prometheus-client-apache
    - icinga2-satellite

  # STAGING

  'cove-staging':
    - cove
    - icinga2-satellite

  # DEVELOPMENT

  # dev3 server can be turned off as soon as we are sure the moves have been successful
  'dev3':
    # This has been moved to dev5
    - opendataservices-website
    # This has been moved to dev7
    - temp
    - icinga2-satellite

  # dev4 server can be turned off as soon as we are sure the moves have been successful
  'dev4':
    # This is being moved to dev7
    - org-ids
    - icinga2-satellite
    - prometheus-client-apache
    # This is being moved to dev7
    - os4d

  'dev5':
    - prometheus-client-apache
    - json-data-ferret
    - opendataservices-website

  'dev7':
    - prometheus-client-apache
    - temp
    - os4d
    - org-ids

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

  # Prometheus on mon-4 is using IP allow-listing for sending emails from our gmail - if we move server/IP that will need attention.
  'mon-4':
    - prometheus-server
    - prometheus-client-apache
    - private.360G-datatester

  # OTHERS

  'snapshotter':
    - icinga2-satellite
    - prometheus-client-apache

  'backups':
    - icinga2-satellite
    - prometheus-client-apache
    - backups

  'dokku*':
    - prometheus-client-standalone
    - dokku

  'analysis-*':
    - prometheus-client-standalone
    - users

  'analysis-1':
    - ocdsdata
    - postgres

  'analysis-2':
    - iatitables

  'oa1':
    - prometheus-client-standalone
    - dokku
    - openactive-conformance-services

