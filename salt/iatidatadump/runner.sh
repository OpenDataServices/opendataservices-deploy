#!/bin/bash

set -e

cd {{ app_dir }}
source .ve/bin/activate
WORKING_DIR={{working_dir}} ./run.sh

{% set files = ["data.zip", "errors.txt", "metadata.json"] %}
{% for file in files %}
mv {{ working_dir }}/{{ file }}  {{ web_data_dir }}/{{ file }}
{% endfor %}
