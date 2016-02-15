# This is a seperate salt SLS file for live, because it includes a reverse
# proxy to hit the dev site for dev branches (and Cove for /validator).
# See apache/ocds-docs-live.conf
#
#
# How to make a new live release:
#
# Merge onto 1.0 in git (in GitHub interface, of locally with a no-ff merge).
#
# Initiate a build on travis (either pushing new commit, or if it's just theme
# changes, hitting rebuild on the old one). Once this is done, check the
# staging site:
# http://ocds-standard.dev3.default.opendataservices.uk0.bigv.io/1.0/en/
# 
# Copy the files: scp -r
# root@dev3.default.opendataservices.uk0.bigv.io:/home/ocds-docs/web/1.0
# 1.0-`date +%F`-1 scp -r 1.0-`date +%F`-1
# root@live2.default.opendataservices.uk0.bigv.io:/home/ocds-docs/web/
# 
# ssh root@live2.default.opendataservices.uk0.bigv.io cd /home/ocds-docs/web/
# rm 1.0; ln -s 1.0-`date +%F`-1 1.0
# 
# To deploy again on the same day, increment the -1 (e.g. -2 etc.)
# 
# If you've made a semantic update to the schema, that should be tagged with a
# patch version (e.g. 1__0__1 on GitHub), and the json to
# /home/ocds-docs/web/schema on live2.
#


include:
  - ocds-docs-common

{% from 'lib.sls' import apache %}
{{ apache('ocds-docs-live.conf') }}

https://github.com/open-contracting/standard-legacy-staticsites.git:
  git.latest:
    - rev: master
    - target: /home/ocds-docs/web/legacy/
    - user: ocds-docs
    - force_fetch: True
    - force_reset: True

mod_include:
  apache_module.enable:
    - name: include
