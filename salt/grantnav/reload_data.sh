#!/bin/bash
set -e
# This command deletes all data, from ALL elasticsearch indices:
#curl -XDELETE 'http://localhost:9200/_all'
{% for branch in pillar.grantnav.branches %}
cd ~/grantnav-{{ branch }}/
source .ve/bin/activate

{% for dataselection in pillar.grantnav.dataselections %}
{% set suffix = pillar.grantnav.deploys.new.datadate %}
cd ~/data_{{ suffix }}/json_{{ dataselection }}
mkdir -p ~/dataload_logs
ES_INDEX=grantnav_{{ dataselection }}_{{ branch }}_{{ suffix }} python -u ~/grantnav-{{ branch }}/dataload/import_to_elasticsearch.py --clean * &> ~/dataload_logs/{{ dataselection }}_{{ branch }}_{{ suffix }}.log
{% endfor %}

deactivate
{% endfor %}
