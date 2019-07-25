# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

base:
  # Install our core sls onto all servers
  '*':
    - core

  # LIVE

  'live2':
    - opendataservices-website
    - icinga2-satellite

  'live3':
    - icinga2-satellite
    - os4d
    - travis-secret-files

  'cove*live*':
    - cove
    - icinga2-satellite

  'grantnav-live*':
    - grantnav
    - icinga2-satellite

  'data-360-live':
    - registry360
    - icinga2-satellite

  'org-ids':
    - org-ids
    - icinga2-satellite

  'bods':
    - icinga2-satellite


  'ocds-docs-staging':
    - icinga2-satellite
    - ocds-docs-staging

  'ocds-docs-live':
    - icinga2-satellite
    - ocds-docs-live
    - ocds-legacy

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
    - os4d
    - registry360
    - ocds-extension-explorer

  'cove*dev*':
    - cove
    - icinga2-satellite

  'cove-dev*':
     - cove_dev_redirects

  'grantnav-dev*':
    - grantnav-es7
    - icinga2-satellite

  'ocdskingfisher-new':
    - postgres11
    - ocdskingfisher
    - ocdskingfisherold
    - ocdskingfisherarchiveonprocess
    - ocdskingfisherprocess
    - ocdskingfisherscrape
    - ocdskingfisheranalyse

  'ocdskingfisher-dev':
    - icinga2-satellite
    - postgres10
    - ocdskingfisher
    - ocdskingfisherold
    - ocdskingfisherprocess
    - ocdskingfisherscrape
    - ocdskingfisheranalyse

  'ocds-kingfisher-archive':
    - postgres11
    - ocdskingfisher
    - ocdskingfisheranalyse
    - ocdskingfisherarchiveonarchive

  'ocds-redash*':
    - ocds-redash

  'ocdskit-web':
    - ocdskit-web

  'standard-search':
    - standard-search
#    - icinga2-satellite

  'pwyf-dev':
    - pwyf-tracker
#    - icinga2-satellite

  'iati-misc':
    - iati-misc
#    - icinga2-satellite


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

