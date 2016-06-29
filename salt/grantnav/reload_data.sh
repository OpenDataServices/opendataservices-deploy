#!/bin/bash
set -e
# This command deletes all data, from ALL elasticsearch indices:
#curl -XDELETE 'http://localhost:9200/_all'
{% for branch in pillar.grantnav.branches %}
cd ~/grantnav-{{ branch }}/
source .ve/bin/activate

{% for dataselection in pillar.grantnav.dataselections %}
cd ~/data/json_{{ dataselection }}
ES_INDEX=grantnav_{{ dataselection }}_{{ branch }} python ~/grantnav-{{ branch }}/dataload/import_to_elasticsearch.py --clean *
{% endfor %}

deactivate
{% endfor %}
