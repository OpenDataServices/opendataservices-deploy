# Values used only on the dev servers
default_branch: 'master'
domain_prefix: 'dev.'
banner_message: 'This is a development site with experimental features. Do not rely on it.'
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '1' 
automatic_reboot: 'true'
extra_cove_branches:
# Add a new branch with the name of the branch, and increment the port number.
# Currently adding a new port number requires a manual uwsgi restart (ie. the
# reload in highstate will fail, so you will need to ssh and run "service uwsgi
# restart" instead)
  - name: resourceprojects-wireframe
    uwsgi_port: 3032
  - name: stevens-fixes
    uwsgi_port: 3033
  - name: 43-catch-conversion-errors
    uwsgi_port: 3034
  - name: resourceprojects-etl
    uwsgi_port: 3035
