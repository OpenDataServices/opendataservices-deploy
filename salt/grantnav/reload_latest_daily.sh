#!/bin/bash
# Reload latest index from data from the datastore
# Creates a new index and deletes the old one once the load is complete

set -e

cd /home/{{ user }}
if [ ! -d "latest_grantnav_data.tar.gz" ]; then
    tar -xvf "latest_grantnav_data.tar.gz"
    rm -rf /home/{{ user }}/latest || true
    mv data latest
fi

cd {{ djangodir }}
source .ve/bin/activate
cd /home/{{ user }}/latest/json_all/
mkdir -p ~/dataload_logs

# New index name
export ES_INDEX=`date +latest_daily_at_%s`

# Old index name
if [ -f /home/{{ user }}/es_index ]; then
  OLD_INDEX_NAME=`cat /home/{{ user }}/es_index`
fi

# Load latest daily data
echo "Loading new index $ES_INDEX"
python -u {{djangodir}}/dataload/import_to_elasticsearch.py --clean * &> /home/{{ user }}/dataload_logs/latest_daily.log || echo "Data loading failed for branch es7 with data from the datastore, see dataload_logs/latest_daily.log for more information."

# Set the application to use new es index name
echo $ES_INDEX > /home/{{ user }}/es_index

# Now we can delete the old index
if [ $OLD_INDEX_NAME ]; then
  echo "Deleting old index $OLD_INDEX_NAME"
  curl -XDELETE 'http://localhost:9200/'$OLD_INDEX_NAME
fi

deactivate
