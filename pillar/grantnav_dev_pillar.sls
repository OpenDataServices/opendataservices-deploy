# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
    - 450_accents_search_fix
  dataselections:
#    - all
    - acceptable_license_valid
#    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2018-08-10'
    current:
      datadate: '2018-08-10'
    old:
      datadate: '2017-08-01'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
