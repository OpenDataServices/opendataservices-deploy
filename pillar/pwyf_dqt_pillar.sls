pwyf_dqt:
  servername: 'dataqualitytester.publishwhatyoufund.org'
  devname: 'dqt-dev.publishwhatyoufund.org'
  checkout_dir: 'data-quality-tester'
  git_url: 'https://github.com/pwyf/data-quality-tester.git'
  branch: 'deploy-tests'
  user: 'dqt'
  static_dir: '/var/www/static/'
  celery_nodes: 4

prometheus:
  client_fqdn: 'prom.dataqualitytester.publishwhatyoufund.org'
