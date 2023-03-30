# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core

  # LIVE

  'live6':
    - prometheus-client-apache
    - cove-opendataservices-coop
    - opendataservices-website
    - domain-redirects
    - org-ids
    - os4d-static

  # STAGING


  # DEVELOPMENT

  'dev8':
    - prometheus-client-apache
    - opendataservices-website
    - cove-opendataservices-coop
    - temp
    - org-ids
    - domain-redirects
    - datatig-real-static-site-demos
    - os4d-static

  'oroi*':
    # Mostly not managed with salt, see the roster for more information.
    - docker-workarounds

  'lillorgid1':
    - prometheus-client-standalone
    - lillorgid-solrserver
    - lillorgid-webapp

  # MONITORING

  # Prometheus on mon-5 is using IP allow-listing for sending emails from our gmail - if we move server/IP that will need attention.
  'mon-5':
    - prometheus-server
    - prometheus-client-apache

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

  'iaticountrydata1':
    - prometheus-client-standalone
    - iaticdfdbackend

  'iatidatastoreclassic-dev-1':
    - prometheus-client-standalone
    - iatidatastoreclassic
    - static-website
    - iaticdfdbackend

  'epds1':
    - prometheus-client-standalone
    - epds
    - postgres
    - dokku

