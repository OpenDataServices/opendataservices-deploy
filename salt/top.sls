# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core

  # LIVE

  'live4':
    - prometheus-client-apache
    - opendataservices-website
    - cove-opendataservices-coop
    - icinga2-satellite
    - domain-redirects

  'live5':
    - prometheus-client-apache
    - os4d
    - org-ids

  'cove*live*':
    - cove
    - icinga2-satellite

  'cove-live-iati-2':
    - prometheus-client-apache

  'cove-live-bods':
    - prometheus-client-apache

  # STAGING

  'cove-staging':
    - cove
    - icinga2-satellite

  # DEVELOPMENT

  'dev5':
    - prometheus-client-apache
    - opendataservices-website

  'dev7':
    - prometheus-client-apache
    - temp
    - os4d
    - org-ids
    - domain-redirects
    - datatig-real-static-site-demos
    # Manually added f500 datasette site 10/11/22 (needed for next weeks, 
    # but not big deal it over-written)

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

  # Prometheus on mon-4 is using IP allow-listing for sending emails from our gmail - if we move server/IP that will need attention.
  'mon-4':
    - prometheus-server
    - prometheus-client-apache
    - private.360G-datatester

  # OTHERS


  'backups':
    - icinga2-satellite
    - prometheus-client-apache
    - backups

  'dokku*':
    - prometheus-client-standalone
    - dokku
  
  'pwyf-index-2022-test':
    - pwyf-tracker-original
    - postgres

  'analysis-*':
    - prometheus-client-standalone
    - users

  'analysis-1':
    - ocdsdata
    - postgres

  'analysis-2':
    - iatitables

  'iatidatastoreclassic1':
    - prometheus-client-standalone
    - iatidatastoreclassic
    - static-website

  'iatidatastoreclassic-dev-1':
    - prometheus-client-standalone
    - iatidatastoreclassic
    - static-website

  'epds1':
    - prometheus-client-standalone
    - epds
    - postgres
    - dokku

