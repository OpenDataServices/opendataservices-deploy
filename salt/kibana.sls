# Salt formula for setting up kibana
kibana-base:
  archive.extracted:
    - name: /opt/
    - source: https://download.elastic.co/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz
    - source_hash: sha1=c925f75cd5799bfd892c7ea9c5936be10a20b119
    - archive_format: tar
    - if_missing: /opt/kibana-4.0.2-linux-x64/

  # Ensure kibana only listens on localhost
  file.append:
    - name: /opt/kibana-4.0.2-linux-x64/config/kibana.yml
    - text: "host: 127.0.0.1"
