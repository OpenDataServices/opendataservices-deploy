#!/bin/bash
set -e
curl -XDELETE 'http://localhost:9200/_all'
cd ~/grantnav
rm -r Valid\ Data/ || true
unzip Valid_Data-$(date +%F).zip;
source .ve/bin/activate
cd Valid\ Data
ES_INDEX=threesixtygiving python ../dataload/import_to_elasticsearch.py --clean *
deactivate
source ../../grantnav-master_before_updateflattentool/.ve/bin/activate
ES_INDEX=threesixtygiving_dev python ../../grantnav-master_before_updateflattentool/dataload/import_to_elasticsearch.py --clean *
source ../../grantnav-master/.ve/bin/activate
ES_INDEX=threesixtygiving_updateflattentool python ../../grantnav-master/dataload/import_to_elasticsearch.py --clean *
