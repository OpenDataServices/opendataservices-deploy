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
  'live6':
     - live6_pillar
     - org-ids_pillar
     - private.org-ids_pillar
     - private.server_live6_pillar

  '*dev*':
     - dev_pillar
     - private.dev_pillar
  'mon*':
     - mon_pillar
     - private.mon_pillar
  'lillorgid1*':
     - private.lillorgid
  'backups':
     - backups_pillar

  'pwyf-index-2022-test':
     - postgres_pillar
     - private.pwyf_tracker
     - pwyf_tracker_2022_dev

  'pwyf-index-2022-live':
     - postgres_pillar
     - private.pwyf_tracker
     - pwyf_tracker_2022

  'pwyf-tracker2024-dev':
     - postgres_pillar
     - private.pwyf_tracker
     - pwyf_tracker_2024_dev

  'analysis-1':
     - postgres_pillar
     - private.analysis1
     - private.ocdsdata

  'analysis-2':
     - private.iatitables

  'oa1':
    - oa1_pillar
    - private.openactive_conformance_services_private

  'iatidatastoreclassic1':
    - private.iatidatastoreclassic1_pillar
    - iatidatastoreclassic1_pillar
    - private.iaticdfdbackend1_pillar
    - iaticdfdbackend1_pillar
    - private.server_iatidatastoreclassic1_pillar

  'iaticountrydata1':
    - private.iaticdfdbackend1_pillar
    - iaticdfdbackend1_pillar
    - private.server_iaticountrydata1_pillar

  'iatidatastoreclassic-dev-1':
    - private.iatidatastoreclassic_dev_1_pillar
    - iatidatastoreclassic_dev_1_pillar
    - private.iaticdfdbackend_dev_1_pillar
    - iaticdfdbackend_dev_1_pillar
    - private.server_iatidatastoreclassic_dev_1_pillar

  'dev8':
    - dev8_pillar
    - private.server_dev8_pillar

  'epds1':
    - postgres_pillar
    - private.epds
    - dokku_epds_dev


  'dokku-bods-live-1':
    - private.server_dokku_bods_live_1_pillar

  'dokku-bods-dev-1':
    - private.server_dokku_bods_dev_1_pillar

  'mon-5':
    - private.server_mon_5_pillar

  'dokku-dev-3':
    - private.server_dokku_dev_3_pillar

  'dokku-live-3':
    - private.server_dokku_live_3_pillar

