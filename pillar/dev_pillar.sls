# Values used only on the dev servers
default_branch: 'master'
domain_prefix: 'dev.'
banner_message: 'This is a development site with experimental features. Do not rely on it.'
grantnav:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '1'
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '1' 
automatic_reboot: 'true'
extra_cove_branches: # [] # remove the [] (empty list) if you re-add some values below
  - name: flatten-tool-updates
    uwsgi_port: 3032
  - name: release-201602
    uwsgi_port: 3033
  - name: 292-dev-schema
    uwsgi_port: 3034
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
# $ killall uwsgi
