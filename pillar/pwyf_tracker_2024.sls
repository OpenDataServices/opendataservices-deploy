pwyf_tracker:
  servername: 2024tracker.publishwhatyoufund.org
  database_url: 'postgresql+psycopg2:///pwyf_tracker'
  https: 'force'
  branch: 'main'
  brightbox_backup:
    subdir: 2024tracker
postgres:
  acls:
   - ['local', 'all', 'postgres', 'peer']
   - ['local', 'pwyf_tracker', 'pwyf_tracker', 'peer']
   - ['local', 'all', 'all', 'md5']
   - ['host', 'all', 'all', '0.0.0.0/0', 'md5']
