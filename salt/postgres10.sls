postgresql-10:
  pkg.installed:
    - pkgs:
      - postgresql-10

/etc/postgresql/10/main/pg_hba.conf:
  file.managed:
    - source: salt://postgres/pg10_hba.conf
