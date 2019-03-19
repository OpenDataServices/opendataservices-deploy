postgresql-11:
  pkgrepo.managed:
    - humanname: PostgreSQL Official Repository
    - name: deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main
    - dist: bionic-pgdg
    - file: /etc/apt/sources.list.d/psql.list
    - key_url: https://www.postgresql.org/media/keys/ACCC4CF8.asc
  pkg.installed:
    - pkgs:
      - postgresql-11

/etc/postgresql/11/main/pg_hba.conf:
  file.managed:
    - source: salt://postgres/ocdskingfisher_pg_hba.conf
