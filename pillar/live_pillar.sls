# Values used only on the live servers
default_branch: 'live'
# URL that OCDS /validator proxies to
ocds_cove_backend: http://cove.cove-live-ocds.default.opendataservices.uk0.bigv.io
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '5' 
    dimension_map: 'file_type=1,page_type=2,form_name=3,language=4,exit_language=5'
  ocds_redirect: True
  larger_uwsgi_limits: True
  uwsgi_as_limit: 3000
  app: cove_ocds
