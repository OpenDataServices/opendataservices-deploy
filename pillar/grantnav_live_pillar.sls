# grantnav live
grantnav:
  allowedhosts: '.live.threesixtygiving.uk0.bigv.io,.threesixtygiving.org'
  server_size: large
  deploy_mode: list
  deploys:
    new:
      datadate: '2018-05-08'
      branch: 'iteration13'
      dataselection: acceptable_license_valid
    current:
      datadate: '2018-05-08'
      branch: 'iteration13'
      dataselection: acceptable_license_valid
    old:
      datadate: '2018-04-06'
      branch: 'iteration12'
      dataselection: acceptable_license_valid
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '9'
