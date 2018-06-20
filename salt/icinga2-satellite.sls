# This set up us not entirely automated, due to the need to sign certificates.
# To finish the setup run:
#   icinga2 node wizard
# Hit enter, except for:
#   Master Common Name (CN from your master setup): mon.opendataservices.coop
#   Master endpoint host (optional, your master's IP address or FQDN): mon.opendataservices.coop
#  (and the ticket which you generate on the master using the command given)
# Then:
#   service icinga2 restart
# Wait approximately 1 minute, then, on the master:
#   icinga2 node update-config
#   service icinga2 restart
# Note that this last step doesn't work for an 18.04 satellite. Instead we must
# manually make copies of files in /etc/icinga2/repository.d/ on the master.

include:
  - icinga2-base
