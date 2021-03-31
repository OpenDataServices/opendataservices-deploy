# Values used only on the dev servers
default_branch: 'master'
dev_robots_txt: True
# URL that OCDS /validator proxies to
ocds_cove_backend: http://cove.cove-dev.default.opendataservices.uk0.bigv.io
domain_prefix: 'dev.'
banner_message: 'This is a development site with experimental features. Do not rely on it.'
cove:
  gitbranch: live
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '1' 
    dimension_map: 'file_type=2,page_type=3,form_name=4,language=5,exit_language=6'
  ocds_redirect: False
  larger_uwsgi_limits: True
  uwsgi_as_limit: 1800
  uwsgi_harakiri: 300
  apache_uwsgi_timeout: 360
  app: cove_iati
  iati: True
org_ids:
  default_branch: 'update-requirements'
  server_name: 'dev.org-id.guide'
  https: 'no'
  uwsgi_port: 3502
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: 'XXX' 
extra_org_ids_branches: [] # remove the [] (empty list) if you re-add some values below
#  - name: test-branch
#    uwsgi_port: 3503

# Do NOT just delete branches from extra_org_ids_branches above! Instead add them to old_extra_org_ids_branches!
# They will be removed from the dev servers.
old_extra_org_ids_branches: [] # remove the [] (empty list) if you re-add some values below


cove_url: http://cove.cove-live-ocds.default.opendataservices.uk0.bigv.io/
automatic_reboot: 'true'
extra_cove_branches: [] # remove the [] (empty list) if you re-add some values below



# Do NOT just delete branches from extra_cove_branches above! Instead add them to old_cove_branches!
# They will be removed from the dev servers.
old_cove_branches: #[] # remove the [] (empty list) if you re-add some values below
  - name: 1159-ocds-group-validation
    app: cove_ocds
  - name: 1206-prolog
    app: cove_iati
  - name: 895-oneOf-messages
    app: cove_ocds
  - name: 1220-improve-non-unique-elements-error
    app: cove_ocds
  - name: openpyxl-commit
    app: cove_iati
  - name: flatten-tool-ods-support
    app: cove_iati
  - name: 1208-iati-cove-orgxml-spreadsheet
    app: cove_iati
  - name: update-flattentool-openpyxl
    app: cove_iati
  - name: master
    app: cove_iati
  - name: downgrade-openpyxl-2-6
    app: cove_iati
  - name: flattentool-177-xml-path-consistency
    app: cove_iati
  - name: update-flattentool
    app: cove_iati
  - name: iati-dev
    app: cove_iati
    servername: iati.dev.cove.opendataservices.coop
  - name: iati-dportal-link
    app: cove_iati
  - name: flattentool-342-last-modified-does-not-convert
    app: cove_iati
    uwsgi_port: 4001
  - name: flattentool-342-last-modified-does-not-convert-360
    app: cove_360
    uwsgi_port: 4003

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

opendataservices_website:
    https: ''
    servername: 'dev.opendataservices.coop'
    serveraliases: ['www.dev.opendataservices.coop']
    default_branch: 'dev'


os4d_apache_https: "no"
