#!/bin/bash

set -e

cd ~/data
git pull > /dev/null

cd ~/eventtig
source .ve/bin/activate
python eventtig-cli.py build ~/data --sqlite  ~/newdata.sqlite

mv  ~/newdata.sqlite ~/data.sqlite

