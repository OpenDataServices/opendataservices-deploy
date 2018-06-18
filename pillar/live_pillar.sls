# Values used only on the live servers
default_branch: 'live'
# URL that OCDS /validator proxies to
ocds_cove_backend: http://cove.cove-live-ocds-2.default.opendataservices.uk0.bigv.io
cove:
  ocds_redirect: True
  larger_uwsgi_limits: True
  # note, for cove-live-ocds-2 these uwsgi_* definitions are superseded by
  # definitions in ocds_live_pillar.sls
  uwsgi_as_limit: 3000
  uwsgi_harakiri: 300
  # apache_uwsgi_timeout is defined here for the benefit of apache httpd on live2,
  # it needs to be "a bit bigger than" the value of uwsgi_harakiri *on cove-live-ocds-2*
  # (which is defined in ocds_live_pillar.sls, *not* above)
  apache_uwsgi_timeout: 1830
  app: cove_ocds
registry360:
  allowedhosts: data.threesixtygiving,.live.threesixtygiving.uk0.bigv.io
