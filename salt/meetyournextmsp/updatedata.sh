#!/bin/bash

set -e

cd ~/data
git pull > /dev/null

cd ~/eventtig
source .ve/bin/activate
now=$(date +'%Y-%m-%d')
python eventtig-cli.py build ~/data --sqlite  ~/newdata.sqlite >> ~/logs/${now}-updatedata.log

mv  ~/newdata.sqlite ~/data.sqlite

