# This is a seperate salt SLS file for live, because it includes a reverse
# proxy to hit the dev site for dev branches (and Cove for /validator).
# See apache/ocds-docs-live.conf
#
#
# How to make a new live release:
#
# (1) Merge onto 1.1 in git (in GitHub interface, or locally with a no-ff merge).
#
# (2) Initiate a build on travis (either pushing new commit, or if it's just theme
# changes, hitting rebuild on the old one). Once this is done, check the
# staging site:
# http://ocds-standard.dev3.default.opendataservices.uk0.bigv.io/1.1/en/
# 
# (3) Copy the files:
#
# VER=1.1            # (for example)
# DATE=$(date +%F)   # or YYYY-MM-DD to match the release date on dev3
#                    # (see ${VER}/en/index.html)
# SEQ=1              # To deploy again on the same day, increment to 2 etc
# 
# # Copy from dev3 to your local box
# scp -r \
#   root@dev3.default.opendataservices.uk0.bigv.io:/home/ocds-docs/web/${VER} \
#   ${VER}-${DATE}-${SEQ}
# 
# # Copy from your local box to live2
# scp -r \
#   ${VER}-${DATE}-${SEQ} \
#   root@live2.default.opendataservices.uk0.bigv.io:/home/ocds-docs/web/
# 
# # Symlink the version number
# ssh root@live2.default.opendataservices.uk0.bigv.io \
#   -c "rm /home/ocds-docs/web/${VER}; ln -sf ${VER}-${DATE}-${SEQ} /home/ocds-docs/web/${VER}"
#
# See also:
#   salt/apache/ocds-docs-live.conf ("set live_versions = [...]")
#   salt/ocds-docs/include/banner_* and version-options.html
#
#
# If you've made a semantic update to the schema, that should be tagged with a
# patch version (e.g. 1__0__1 on GitHub), and the json should be copied to
# /home/ocds-docs/web/schema on live2.


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

/home/ocds-docs/web/robots.txt:
  file.managed:
    - source: salt://ocds-docs/robots_live.txt
    - user: ocds-docs
