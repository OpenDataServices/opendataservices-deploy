# Values used only on the dev servers
default_branch: 'master'
dev_robots_txt: True
# URL that OCDS /validator proxies to
domain_prefix: 'dev.'
banner_message: 'This is a development site with experimental features. Do not rely on it.'
org_ids:
  default_branch: 'live'
  server_name: 'dev.org-id.guide'
  https: 'no'
  uwsgi_port: 3502
  piwik:
    url: '//mon.opendataservices.coop/'
    site_id: 'XXX' 
extra_org_ids_branches: [] # remove the [] (empty list) if you re-add some values below
#  - name: test-branch
#    uwsgi_port: 3503

# Do NOT just delete branches from extra_org_ids_branches above! Instead add them to old_extra_org_ids_branches!
# They will be removed from the dev servers.
old_extra_org_ids_branches: [] # remove the [] (empty list) if you re-add some values below


automatic_reboot: 'true'



os4d_apache_https: "no"

cove_opendataservices_coop:
  servername: 'dev.staticcove.opendataservices.coop'
  https: 'no'

os4d_static:
  servername: 'dev.os4d.opendataservices.coop'
  https: 'no'
  branch: 'live'
