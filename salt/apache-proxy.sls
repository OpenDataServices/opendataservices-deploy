include:
  - apache

proxy:
    apache_module.enabled

# This given a long name to avoid name conflicts
apache_proxy_sls_proxy_http:
  apache_module.enabled:
    - name: proxy_http

headers:
    apache_module.enabled
