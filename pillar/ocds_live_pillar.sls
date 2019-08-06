# Values used only on the Cove OCDS server
default_branch: 'master'
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '20' 
    dimension_map: 'file_type=1,page_type=2,form_name=3,language=4,exit_language=5'
  allowedhosts: '.cove.opencontracting.uk0.bigv.io,.standard.open-contracting.org'
  ocds_redirect: False
  google_analytics_id: 'UA-35677147-1'
  larger_uwsgi_limits: True
  # Note: these values supersede the much smaller values in live_pillar.sls
  uwsgi_as_limit: 12000
  uwsgi_harakiri: 1800
