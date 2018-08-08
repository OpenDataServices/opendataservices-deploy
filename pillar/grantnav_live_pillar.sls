# grantnav live
grantnav:
  allowedhosts: '.live.threesixtygiving.uk0.bigv.io,.threesixtygiving.org'
  server_size: large
  deploy_mode: list
  deploys:
    new:
      datadate: '2018-08-01'
      branch: 'iteration17.1'
      dataselection: acceptable_license_valid
    current:
      datadate: '2018-08-01'
      branch: 'iteration17.1'
      dataselection: acceptable_license_valid
    old:
      datadate: '2018-07-05'
      branch: 'iteration16'
      dataselection: acceptable_license_valid
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '9'
