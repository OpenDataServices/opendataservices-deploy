/etc/apache2/envvars:
  file.uncomment:
    - regex: \. \/etc\/default\/locale

apache2:
  # Ensure that  apache is installed
  pkg:
    - installed
  # Ensure apache running, and reload if any of the conf files change
  service:
    - running
    - enable: True
    - reload: True
    - watch:
      - file: /etc/apache2/sites-available/*
      - file: /etc/apache2/sites-enabled/*
