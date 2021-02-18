json_data_ferret_installs:
  - name: main
    branch: main
    servername: 'jsondataferret.dev5.default.opendataservices.uk0.bigv.io'
    postgres_user: jdf_main
    postgres_name: jdf_main
    uwsgi_port: 3501

# Do NOT just delete branches from json_data_ferret_installs above! Instead add them to json_data_ferret_installs_to_remove!
# They will be removed from the servers.
# THIS WILL DELETE ALL DATA IN THE DATABASE TOO - BE CAREFUL!
json_data_ferret_installs_to_remove:
  - name: indigo
    branch: indigo
    servername: 'indigo.dev5.default.opendataservices.uk0.bigv.io'
    postgres_user: jdf_indigo
    postgres_name: jdf_indigo
    uwsgi_port: 3502
  - name: master
    branch: master
    servername: 'jsondatatferret.dev5.default.opendataservices.uk0.bigv.io'
    postgres_user: jdf_master
    postgres_name: jdf_master
    uwsgi_port: 3501

