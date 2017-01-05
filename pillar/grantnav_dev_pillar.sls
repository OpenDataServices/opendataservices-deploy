# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
    - iteration07.5
  dataselections:
    - all
    - acceptable_license_valid
    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2016-12-01_2'
    current:
      datadate: '2016-12-01_2'
    old:
      datadate: '2016-10-25'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
