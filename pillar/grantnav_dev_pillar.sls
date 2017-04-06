# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
    - iteration07.6
  dataselections:
    - all
    - acceptable_license_valid
    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2017-02-03'
    current:
      datadate: '2017-01-10'
    old:
      datadate: '2016-12-01_2'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
