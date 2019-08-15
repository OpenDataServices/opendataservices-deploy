# This file defines what pillars should be used for our servers
# For each environment we have a public and a private pillar

base:
  '*':
     - common_pillar
     - private.common_pillar
  '*live*':
     - live_pillar
     - private.live_pillar
  '*live-ocds*':
     - ocds_live_pillar
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
  'standard-search':
     - private.standard_search_pillar
  '*360*':
     - 360_pillar
  '*360-live':
     - 360_live_pillar
  'cove-live':
     - old_cove_live_pillar

  'grantnav-dev*':
     - grantnav_dev_pillar
     - private.grantnav_dev_pillar

  'grantnav-live*':
     - grantnav_live_pillar
     - private.grantnav_live_pillar

  'tmp2':
     - tmp_pillar
     - private.dev_pillar

  'ocdskit-web':
     - ocdskit_web_pillar

  'ocdskingfisher*':
     - private.ocdskingfisher_pillar

  'ocdskingfisher':
     - ocdskingfisher_live_pillar
     - private.ocdskingfisher_live_pillar

  'ocdskingfisher-new':
     - ocdskingfisher_live_pillar
     - private.ocdskingfisher_live_pillar

  'ocds-kingfisher-archive':
     - ocdskingfisher_live_pillar
     - private.ocdskingfisher_live_pillar
     - private.ocdskingfisher_pillar

  'ocds-redash*':
     - private.ocds_redash_pillar
     - private.ocds_live_pillar

  'ocds-docs-*':
     - private.ocds_live_pillar

  '*live-bods*':
     - bods_live_pillar
  '*dev-bods*':
     - bods_dev_pillar

  'cove-live-oc4ids':
     - oc4ids_live_pillar

  'pwyf-dev':
     - pwyf_tracker
     - private.pwyf_tracker
