# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
    - 466-date-only
  dataselections:
#    - all
    - acceptable_license_valid
#    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2019-01-10'
    current:
      datadate: '2019-01-10'
    old:
      datadate: '2019-01-10'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
