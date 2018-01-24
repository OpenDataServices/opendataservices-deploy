#!/bin/bash
set -e
# This command deletes all data, from ALL elasticsearch indices:
#curl -XDELETE 'http://localhost:9200/_all'

cd ~
if [ ! -d "data_{{ pillar.grantnav.deploys[deploy].datadate }}" ]; then
    tar -xvf "data_{{ pillar.grantnav.deploys[deploy].datadate }}.tar.gz"
    mv data "data_{{ pillar.grantnav.deploys[deploy].datadate }}"
fi

{% macro load(dataselection, branch, suffix, es_index) %}
cd ~/grantnav-{{ branch }}/
source .ve/bin/activate
cd ~/data_{{ suffix }}/json_{{ dataselection }}
mkdir -p ~/dataload_logs
{% set logfile = '/home/grantnav/dataload_logs/'+dataselection+'_'+branch+'_'+suffix+'.log' %}
ES_INDEX={{ es_index }} python -u ~/grantnav-{{ branch }}/dataload/import_to_elasticsearch.py --clean * &> {{ logfile }} || echo "Data loading failed for branch {{ branch }} with dataselection {{ dataselection }}, see {{ logfile }} for more information."
deactivate
{% endmacro %}

{% if pillar.grantnav.deploy_mode == 'matrix' %}

{% for dataselection in pillar.grantnav.dataselections %}
{{ load(dataselection, branch, pillar.grantnav.deploys[deploy].datadate, 'grantnav_'+dataselection+'_'+branch+'_'+pillar.grantnav.deploys[deploy].datadate) }}
{% endfor %}

{% else %}
{{ load(pillar.grantnav.deploys[deploy].dataselection, pillar.grantnav.deploys[deploy].branch, pillar.grantnav.deploys[deploy].datadate, 'grantnav_'+pillar.grantnav.deploys[deploy].datadate) }}
{% endif %}
