# Values used only on the dev servers
default_branch: 'master'
# URL that OCDS /validator proxies to
ocds_cove_backend: http://cove.cove-dev.default.opendataservices.uk0.bigv.io
domain_prefix: 'dev.'
banner_message: 'This is a development site with experimental features. Do not rely on it.'
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '1' 
    dimension_map: 'file_type=2,page_type=3,form_name=4,language=5,exit_language=6'
  ocds_redirect: False
  larger_uwsgi_limits: True
  uwsgi_as_limit: 1800
  app: cove_ocds
org_ids:
  default_branch: 'master'
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: 'XXX' 
cove_url: http://cove.cove-live-ocds.default.opendataservices.uk0.bigv.io/
automatic_reboot: 'true'
extra_cove_branches: #[] # remove the [] (empty list) if you re-add some values below
  - name: release-201705
    uwsgi_port: 3045
    app: cove_ocds
  - name: ocds-dev-schema
    uwsgi_port: 3046
    app: cove_ocds
  - name: master
    uwsgi_port: 3047
    app: cove_iati
    servername: iati.cove.opendataservices.coop
  - name: release-201707
    uwsgi_port: 3048
    app: cove_ocds

# Add a new branch with the name of the branch, and increment the port number.
# Currently adding a new port number requires a manual uwsgi restart (ie. the
# reload in highstate will fail, so you will need to ssh and run "service uwsgi
# restart" instead)
#
# To set these up from scratch (e.g. if you've
# removed one) you can run these commands on the
# server: (and then the salt state)
# $ rm /etc/uwsgi/apps-enabled/cove-*.ini
# $ rm /etc/apache2/sites-available/cove-*.conf
# $ rm /etc/apache2/sites-enabled/cove-*.conf
# $ rm /etc/fail2ban/jail.d/uwsgi-cove-*.conf
# $ killall uwsgi
