# grantnav development
grantnav:
  allowedhosts: '.default.threesixtygiving.uk0.bigv.io'
  branches:
    - master
    - iteration06
  dataselections:
    - all
    - acceptable_license_valid
    - valid
  deploy_mode: matrix
  deploys:
    new:
      datadate: '2016-09-14.1'
    current:
      datadate: '2016-09-14.1'
    old:
      datadate: '2016-08-31'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '6'
