#!/bin/bash

set -e

cd /home/{{ user }}/real-staticsite-demos
git pull
source .ve/bin/activate
pip3 install -U git+https://github.com/DataTig/DataTig.git@main#egg=datatig
./build.sh
