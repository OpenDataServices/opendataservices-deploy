libapache2-mod-php5:
  pkg.installed:
    - watch_in:
      - service: apache2
