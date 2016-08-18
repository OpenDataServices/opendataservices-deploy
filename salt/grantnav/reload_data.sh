#!/bin/bash
set -e
# This command deletes all data, from ALL elasticsearch indices:
#curl -XDELETE 'http://localhost:9200/_all'

cd ~
if [ ! -d "data_{{ pillar.grantnav.deploys.new.datadate }}" ]; then
    tar -xvf "data_{{ pillar.grantnav.deploys.new.datadate }}.tar.gz"
    mv data "data_{{ pillar.grantnav.deploys.new.datadate }}"
fi

{% macro load(dataselection, branch, suffix, es_index) %}
cd ~/grantnav-{{ branch }}/
source .ve/bin/activate
cd ~/data_{{ suffix }}/json_{{ dataselection }}
mkdir -p ~/dataload_logs
ES_INDEX={{ es_index }} python -u ~/grantnav-{{ branch }}/dataload/import_to_elasticsearch.py --clean * &> ~/dataload_logs/{{ dataselection }}_{{ branch }}_{{ suffix }}.log
deactivate
{% endmacro %}

{% if pillar.grantnav.deploy_mode == 'matrix' %}

{% for branch in pillar.grantnav.branches %}
{% for dataselection in pillar.grantnav.dataselections %}
{{ load(dataselection, branch, pillar.grantnav.deploys.new.datadate, 'grantnav_'+dataselection+'_'+branch+'_'+pillar.grantnav.deploys.new.datadate) }}
{% endfor %}
{% endfor %}

{% else %}
{{ load(pillar.grantnav.deploys.new.dataselection, pillar.grantnav.deploys.new.branch, pillar.grantnav.deploys.new.datadate, 'grantnav_'+pillar.grantnav.deploys.new.datadate) }}
{% endif %}
