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
    - domain-redirects
    - org-ids
    - os4d-static

  # STAGING


  # DEVELOPMENT

  'dev8':
    - prometheus-client-apache
    - cove-opendataservices-coop
    - temp
    - org-ids
    - domain-redirects
    - datatig-real-static-site-demos
    - os4d-static


  # MONITORING

  # Prometheus on mon-5 is using IP allow-listing for sending emails from our gmail - if we move server/IP that will need attention.
  'mon-5':
    - prometheus-server
    - prometheus-client-apache

  # OTHERS


  'backups':
    - prometheus-client-apache
    - backups

  'dokku*':
    - prometheus-client-standalone
    - dokku
  
  'pwyf-index-2022-*':
    - pwyf-tracker-2022
    - postgres

  'pwyf-tracker2024-*':
    - prometheus-client-apache
    - pwyf-tracker
    - postgres

  'analysis-*':
    - prometheus-client-standalone
    - users

#  'analysis-1':
#    - ocdsdata
#    - postgres

#  'analysis-2':
#    - iatitables

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

  'afdbdev1':
    - prometheus-client-standalone
    - docker
    - afdb

  'iatitables1':
    - prometheus-client-standalone
    - iatitables2

  'iatidatadump1':
    - prometheus-client-standalone
    - iatidatadump
