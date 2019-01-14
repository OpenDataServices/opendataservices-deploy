# grantnav live
grantnav:
  allowedhosts: '.live.threesixtygiving.uk0.bigv.io,.threesixtygiving.org'
  server_size: large
  deploy_mode: list
  deploys:
    new:
      datadate: '2019-01-10'
      branch: 'iteration21'
      dataselection: acceptable_license_valid
    current:
      datadate: '2019-01-10'
      branch: 'iteration21'
      dataselection: acceptable_license_valid
    old:
      datadate: '2018-12-03'
      branch: 'iteration18'
      dataselection: acceptable_license_valid
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '9'
