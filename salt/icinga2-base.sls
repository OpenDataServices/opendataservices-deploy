icinga2:
  pkgrepo.absent:
    - ppa: formorer/icinga
  pkg.removed:
    - pkgs:
      - icinga2
      - nagios-plugins
      - nagios-plugins-contrib

/usr/lib/nagios/plugins/check_memory:
  file.absent

/etc/icinga2:
  file.absent
