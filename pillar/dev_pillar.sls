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
  - name: minor-live-improvements
    uwsgi_port: 3032
