#!/bin/bash
# This is a convencience script for running the same tasks as listed in a Cove
# deploy pull request (assuming that you have the cove git repo in the same
# directory as opendataservices-deploy).
# You should check that the commands here are up to date with what's in the
# pull request, and also perform any manual steps (e.g. checking that the
# commit listed in the footer is correct).
set -e
salt-ssh --state-output=mixed 'cove-live' state.highstate  
pushd ../cove
git checkout live
git pull
source .ve/bin/activate
pip install --upgrade -r requirements_dev.txt
CUSTOM_SERVER_URL=http://cove.opendataservices.coop/ PREFIX_360=/360/ py.test fts
popd
salt-ssh --state-output=mixed 'cove-live-ocds' state.highstate  
pushd ../cove
CUSTOM_SERVER_URL=http://standard.open-contracting.org PREFIX_OCDS=/validator/ py.test fts
