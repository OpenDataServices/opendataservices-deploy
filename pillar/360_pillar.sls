cove:
  prefixmap: '360=^/?'
  allowedhosts: '.threesixtygiving.org,.threesixtygiving.uk0.bigv.io'
  https: 'no'
  app: cove_360
extra_cove_branches: #[] # remove the [] (empty list) if you re-add some values below
  - name: release-201611
    uwsgi_port: 3040
  - name: 601-app-separation-with-IATI
    uwsgi_port: 3014
    app: cove_360
