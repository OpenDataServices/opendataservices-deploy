#!/bin/bash

set -e

# Update, install requirements and Run Collector
cd /home/ocdsext/collector
git pull
source .ve/bin/activate
pip install -r requirements.txt
python cli.py
deactivate

# Update and install requirements of Explorer
cd /home/ocdsext/explorer
git pull
source .ve/bin/activate
pip install -r requirements.txt
deactivate

# Copy data file to explorer site
cp /home/ocdsext/collector/output_dir/data.json /home/ocdsext/explorer/extension_explorer/local_data.json

# Trigger reload
touch /home/ocdsext/explorer/wsgi.py
