pwyf_tracker:
  servername: 2024tracker-dev.publishwhatyoufund.org
  database_url: 'postgresql+psycopg2:///pwyf_tracker_live_copy_3'
  https: 'force'
  branch: 'max-points-bug'
  brightbox_backup:
    subdir: 2024tracker-dev
  prune_backups:
    True
prometheus:
  client_fqdn: xvm-173-103.dc0.ghst.net
postgres:
  acls:
   - ['local', 'all', 'postgres', 'peer']
   - ['local', 'all', 'pwyf_tracker', 'peer']
   - ['local', 'all', 'all', 'md5']
   - ['host', 'all', 'all', '0.0.0.0/0', 'md5']
