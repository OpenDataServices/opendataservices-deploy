# top.sls defines which states should be installed onto which servers
# and is used by the state.highstate command (see README)

live:
  # Install our core sls onto all servers
  '*':
    - core
  # Our main live server
  'live1':
    - opencontracting
    - opendataservices-website
