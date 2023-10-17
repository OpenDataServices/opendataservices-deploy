#!/usr/bin/bash
source .ve/bin/activate
flask --app iatidatacube.app download
flask --app iatidatacube.app process
flask --app iatidatacube.app update
flask --app iatidatacube.app group
./scripts/createBulkDownloadZIPs.sh
