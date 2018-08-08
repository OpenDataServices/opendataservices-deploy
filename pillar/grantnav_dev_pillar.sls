# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
  dataselections:
#    - all
    - acceptable_license_valid
#    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2018-08-01'
    current:
      datadate: '2018-08-01'
    old:
      datadate: '2017-07-05'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
