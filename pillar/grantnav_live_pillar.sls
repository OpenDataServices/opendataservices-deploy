# grantnav live
grantnav:
  allowedhosts: '.live.threesixtygiving.uk0.bigv.io,.threesixtygiving.org'
  server_size: large
  deploy_mode: list
  deploys:
    new:
      datadate: '2018-07-05'
      branch: 'iteration15'
      dataselection: acceptable_license_valid
    current:
      datadate: '2018-07-05'
      branch: 'iteration15'
      dataselection: acceptable_license_valid
    old:
      datadate: '2018-06-04'
      branch: 'iteration14'
      dataselection: acceptable_license_valid
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '9'
