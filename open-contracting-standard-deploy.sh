echo "$PRIVATE_KEY" | tr '#' '\n' | tr '_' ' ' > id_rsa
chmod 600 id_rsa
echo '|1|FkTASz83nlFnGSnvrDpt8jGNYko=|iuezK/A43QOIAZied/7LNZ30LGA= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOiwQfg1hM1fcXxtssbgfmrnj2iSNounLWkgeWjU9Fr+slHUpcSt0Gk8o3jihTIXqR3z/KgSPqKmaDv3GIEzwBo=' >> ~/.ssh/known_hosts
rsync -e 'ssh -i id_rsa' -av --delete build/ ocds-docs@dev3.default.opendataservices.uk0.bigv.io:~/web/$TRAVIS_BRANCH

