# Values used only on the tmp2 server (which does not currently exist)
# This pillar is retained as a template for the next time we need a temporary server

default_branch: 'master'
# URL that OCDS /validator proxies to
ocds_cove_backend: http://cove.cove-dev.default.opendataservices.uk0.bigv.io
domain_prefix: 'tmp2.'
banner_message: 'This is a temporary site with highly experimental features. Proceed at your own risk.'
cove:
  piwik:
    url: '//mon.opendataservices.coop/piwik/'
    site_id: '1' 
    dimension_map: 'file_type=2,page_type=3,form_name=4,language=5,exit_language=6'
  ocds_redirect: False
  larger_uwsgi_limits: True
  uwsgi_as_limit: 1800
cove_url: http://cove.cove-live-ocds.default.opendataservices.uk0.bigv.io/
automatic_reboot: 'true'
extra_cove_branches: # [] # remove the [] (empty list) if you re-add some values below
  - name: release-201607
    uwsgi_port: 3039
  - name: release-201611
    uwsgi_port: 3040
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
