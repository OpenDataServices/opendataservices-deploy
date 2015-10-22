# This file defines what pillars should be used for our servers
# For each environment we have a public and a private pillar

base:
  '*':
     - common_pillar
     - private.common_pillar
  '*live*':
     - live_pillar
     - private.live_pillar
  '*dev*':
     - dev_pillar
     - private.dev_pillar
  'mon*':
     - mon_pillar
     - private.mon_pillar
  'nrgi-dev':
     - private.nrgi_dev_pillar
     - nrgi_dev_pillar
  'nrgi-dev2':
     - private.nrgi_dev2_pillar
     - nrgi_dev2_pillar
  'backups':
     - backups_pillar
