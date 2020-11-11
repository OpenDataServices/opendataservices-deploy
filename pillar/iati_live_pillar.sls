# Values used only on the Cove OCDS server
default_branch: 'master'
cove:
  gitbranch: live
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '18' 
    dimension_map: 'file_type=1,page_type=2,form_name=3,language=4,exit_language=5'
  iati: True
  servername: iati.cove.opendataservices.coop
  allowedhosts: '.iati.cove.opendataservices.coop'
  larger_uwsgi_limits: True
  uwsgi_as_limit: 12000
  uwsgi_harakiri: 1800
  app: cove_iati
  https: 'force'

