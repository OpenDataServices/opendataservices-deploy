# grantnav live
grantnav:
  allowedhosts: '.live.threesixtygiving.uk0.bigv.io,.threesixtygiving.org'
  server_size: large
  deploy_mode: list
  deploys:
    new:
      datadate: '2019-05-01'
      branch: 'iteration22'
      dataselection: acceptable_license_valid
    current:
      datadate: '2019-05-01'
      branch: 'iteration22'
      dataselection: acceptable_license_valid
    old:
      datadate: '2019-04-01'
      branch: 'iteration22'
      dataselection: acceptable_license_valid
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '9'
