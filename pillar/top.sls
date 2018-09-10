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
  'involve':
     - involve_pillar
     - private.involve_pillar
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

  'ocdskingfisher*':
     - private.ocdskingfisher_pillar

  'ocds-redash*':
     - private.ocds_redash_pillar

  'sedl-db':
     - private.sedl-db_pillar

  'sedl-redash*':
     - private.sedl_redash_pillar
