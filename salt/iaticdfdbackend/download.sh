#!/usr/bin/bash
source .ve/bin/activate
flask --app iatidatacube.app download
flask --app iatidatacube.app process
#flask --app iatidatacube.app drop_all
flask --app iatidatacube.app setup-codelists
flask --app iatidatacube.app update
