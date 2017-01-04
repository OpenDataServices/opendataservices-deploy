# grantnav live
grantnav:
  allowedhosts: '.live.threesixtygiving.uk0.bigv.io,.threesixtygiving.org'
  server_size: large
  deploy_mode: list
  deploys:
    new:
      datadate: '2016-12-01_2'
      branch: 'iteration07.4'
      dataselection: acceptable_license_valid
    current:
      datadate: '2016-12-01_2'
      branch: 'iteration07.4'
      dataselection: acceptable_license_valid
    old:
      datadate: '2016-10-25'
      branch: 'iteration07.3'
      dataselection: acceptable_license_valid
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '9'
