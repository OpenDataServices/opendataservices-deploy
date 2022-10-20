# Values used only on the Cove BODS server
default_branch: 'master'
cove:
  app: cove_project
  uwsgi_port: 3032  # Can't use default 3031 on Ubuntu 18 till https://github.com/unbit/uwsgi/issues/1491 is fixed
  piwik:
    url: '//mon.opendataservices.coop/'
    site_id: '23'
    dimension_map: 'file_type=1,page_type=2,form_name=3,language=4,exit_language=5'
  giturl: 'https://github.com/openownership/cove-bods.git'
  allowedhosts: '.default.opendataservices.uk0.bigv.io,datareview.openownership.org'
  ocds_redirect: False
  larger_uwsgi_limits: True
  # Note: these values supersede the much smaller values in live_pillar.sls
  uwsgi_as_limit: 12000
  uwsgi_harakiri: 1800
  https: 'force'
  servername: 'datareview.openownership.org'
