# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
    - iteration07.6
    - ni-geography
    - cabinet
  dataselections:
    - all
    - acceptable_license_valid
    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2017-11-15'
    current:
      datadate: '2017-10-04'
    old:
      datadate: '2017-09-06'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
