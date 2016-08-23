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
      datadate: '2016-08-22'
    current:
      datadate: '2016-08-16'
    old:
      datadate: '2016-08-16'
