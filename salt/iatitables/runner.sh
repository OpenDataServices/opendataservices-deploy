#!/bin/bash

set -e

cd {{ app_dir }}
source .ve/bin/activate
IATI_TABLES_S3_DESTINATION=- IATI_TABLES_SCHEMA=iati IATI_TABLES_OUTPUT={{ dir }} DATABASE_URL={{ db_url }} python runner.py

{% set files = ["stats.json", "iati.sqlite.gz", "iati.db.gz","iati.sqlite", "iati.sqlite.zip", "activities.json.gz", "iati_csv.zip", "iati.custom.pg_dump", "iati.dump.gz"] %}
{% for file in files %}
mv {{ working_dir }}/{{ file }}  {{ web_data_dir }}/{{ file }}
{% endfor %}
