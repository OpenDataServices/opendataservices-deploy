# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  server_size: small
  branches:
    - master
    - iteration08
    - 420-other-currency-changes
  dataselections:
#    - all
    - acceptable_license_valid
#    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2018-01-05'
    current:
      datadate: '2018-01-05'
    old:
      datadate: '2017-12-04'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
