# This file defines what pillars should be used for our servers
# For each environment we have a public and a private pillar

base:
  '*':
     - common_pillar
     - private.common_pillar
     - private.prometheus_pillar
  '*live*':
     - live_pillar
     - private.live_pillar
  '*live-iati*':
     - iati_live_pillar
  '*staging*':
     - staging_pillar
     - private.staging_pillar
  '*dev*':
     - dev_pillar
     - private.dev_pillar
  'mon*':
     - mon_pillar
     - private.mon_pillar
  'backups':
     - backups_pillar
  'org-ids':
     - org-ids_pillar
     - private.org-ids_pillar
  '*360*':
     - 360_pillar
  '*360-live':
     - 360_live_pillar
  'datastore-360-live':
     - 360_datastore_live_pillar
     - private.360_datastore_live_pillar

  'grantnav-dev*':
     - grantnav_dev_pillar
     - private.grantnav_dev_pillar

  'grantnav-live*':
     - grantnav_live_pillar
     - private.grantnav_live_pillar

  'tmp2':
     - tmp_pillar
     - private.dev_pillar

  '*live-bods*':
     - bods_live_pillar
  '*dev-bods*':
     - bods_dev_pillar

  'pwyf-dev':
     - pwyf_tracker
     - private.pwyf_tracker

  'pwyf-tracker-dev':
     - pwyf_tracker_original
     - private.pwyf_tracker_original

  'pwyf-tracker-2019':
     - pwyf_tracker_2019
     - private.pwyf_tracker_original

  'pwyf-dqt-*':
    - pwyf_dqt_pillar
    - private.pwyf_dqt_pillar

  'pwyf-merger':
    - pwyf_merger_pillar
    - private.pwyf_merger_pillar
