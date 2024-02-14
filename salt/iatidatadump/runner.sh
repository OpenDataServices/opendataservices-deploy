#!/bin/bash

set -e

cd {{ app_dir }}
source .ve/bin/activate
WORKING_DIR={{working_dir}} ./run.sh

python3 /home/{{ user }}/make_gist_data.py

{% set files = ["data.zip", "errors.txt", "metadata.json"] %}
{% for file in files %}
mv {{ working_dir }}/{{ file }}  {{ web_data_dir }}/{{ file }}
{% endfor %}

cat {{ web_data_dir }}/metadata.json >> {{ web_data_dir }}/successful_runs.txt

{% if gist_metadata_id and gist_github_token %}
curl -X PATCH https://api.github.com/gists/{{ gist_metadata_id }} \
     -H 'Content-Type: application/json' \
     -H "Accept: application/vnd.github+json" \
     -H 'Authorization: Bearer {{ gist_github_token }}' \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     -d '@/home/iatidatadump/working_data/gist_metadata.json'
{% endif %}

{% if gist_errors_id and gist_github_token %}
curl -X PATCH https://api.github.com/gists/{{ gist_errors_id }} \
     -H 'Content-Type: application/json' \
     -H "Accept: application/vnd.github+json" \
     -H 'Authorization: Bearer {{ gist_github_token }}' \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     -d '@/home/iatidatadump/working_data/gist_errors.json'
{% endif %}

