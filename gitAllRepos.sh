#!/bin/bash -e

# git wraper for commands to run across all repos. Only usable from the root directory
# Examples:
#  $ gitAllRepos.sh status
#  $ gitAllRepos.sh grep live

git $1  ${@:2}
cd ./salt/private/
git $1  ${@:2}
cd ../../pillar/private/
git $1 ${@:2}
