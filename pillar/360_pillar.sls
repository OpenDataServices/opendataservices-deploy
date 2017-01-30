cove:
  prefixmap: '360=^/?'
  allowedhosts: '.threesixtygiving.org,.threesixtygiving.uk0.bigv.io'
  # Only 360 Cove servers are on 16.04 atm,
  # so are the only ones we can enable https on.
  https: 'yes'
extra_cove_branches: #[] # remove the [] (empty list) if you re-add some values below
  - name: release-201611
    uwsgi_port: 3040
  - name: 504-rearange-boxes
    uwsgi_port: 3041
