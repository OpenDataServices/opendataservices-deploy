# This set up us not entirely automated, due to the need to sign certificates.
# To finish the setup run:
#   icinga2 node wizard
# Hit enter, except for:
#   Master Common Name (CN from your master setup): mon.opendataservices.coop
#   Master endpoint host (optional, your master's IP address or FQDN): mon.opendataservices.coop
#  (and the ticket which you generate on the master using the command given)
# Then:
#   service icinga2 restart
# And on the master:
#   icinga2 node update-config
#   service icinga2 restart

include:
  - icinga2-base
