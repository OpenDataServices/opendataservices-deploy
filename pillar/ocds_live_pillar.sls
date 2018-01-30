# Values used only on the Cove OCDS server
default_branch: 'master'
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '5'
  allowedhosts: '.default.opendataservices.uk0.bigv.io,.standard.open-contracting.org'
  prefixmap: 'ocds=validator/'
  ocds_redirect: False
  google_analytics_id: 'UA-35677147-1'
  larger_uwsgi_limits: True
  # Note: these values supersede the much smaller values in live_pillar.sls
  uwsgi_as_limit: 12000
  uwsgi_harakiri: 1800
