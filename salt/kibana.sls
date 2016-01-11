# Salt formula for setting up kibana
kibana-base:
  archive.extracted:
    - name: /opt/
    - source: https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz
    - source_hash: sha1=115ba22882df75eb5f07330b7ad8781a57569b00
    - archive_format: tar
    - if_missing: /opt/kibana-4.3.1-linux-x64/

  # Ensure kibana only listens on localhost
  file.append:
    - name: /opt/kibana-4.3.1-linux-x64/config/kibana.yml
    - text: "host: 127.0.0.1"
