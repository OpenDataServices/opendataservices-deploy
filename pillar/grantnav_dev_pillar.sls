# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master-next-major-version
  dataselections:
#    - all
    - acceptable_license_valid
#    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2019-07-03'
    current:
      datadate: '2019-07-03'
    old:
      datadate: '2019-07-03'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
