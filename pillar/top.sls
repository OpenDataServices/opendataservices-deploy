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
  'live4':
     - live4_pillar
     - private.org-ids-datatig_pillar
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

  'live5':
     - org-ids_pillar
     - private.org-ids_pillar

  'tmp2':
     - tmp_pillar
     - private.dev_pillar

  '*live-bods*':
     - bods_live_pillar
  '*dev-bods*':
     - bods_dev_pillar

  'pwyf-index-2022-test':
     - postgres_pillar
     - private.pwyf_tracker_original
     - pwyf_tracker_original

  'analysis-1':
     - postgres_pillar
     - private.analysis1
     - private.ocdsdata

  'analysis-2':
     - private.iatitables

  'oa1':
    - oa1_pillar
    - private.openactive_conformance_services_private

  'dokku-dev-2':
    - dokku_dev_2_pillar

  'dokku-live-2':
    - dokku_live_2_pillar

  'iatidatastoreclassic1':
    - private.iatidatastoreclassic1_pillar
    - iatidatastoreclassic1_pillar
    - private.iaticdfdbackend1_pillar
    - iaticdfdbackend1_pillar

  'iatidatastoreclassic-dev-1':
    - private.iatidatastoreclassic_dev_1_pillar
    - iatidatastoreclassic_dev_1_pillar
    - private.iaticdfdbackend_dev_1_pillar
    - iaticdfdbackend_dev_1_pillar

  'dev7':
    - dev7_pillar

  'dev8':
    - dev8_pillar

  'epds1':
    - postgres_pillar
    - private.epds
    - dokku_epds_dev

