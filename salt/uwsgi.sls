uwsgi:
  # Ensure that uwsgi is installed
  pkg:
    - installed
  # Ensure uwsgi running, and reload if any of the conf files change
  service:
    - running
    - enable: True
    - reload: True

# fail2ban filter config for uwsgi
# (the f2b uwsgi jails are set up in lib.sls for each uwsgi instance)
/etc/fail2ban/filter.d/uwsgi.conf:
  file.managed:
    - source: salt://fail2ban/filter.d/uwsgi.conf
