#!/bin/bash
set -e

echo "--------------------- DEPLOY"
git checkout master
git pull

echo "--------------------- PILLAR / PRIVATE"
cd pillar/private
git checkout master
git pull
cd ../..

echo "--------------------- SALT / PRIVATE"
cd salt/private
git checkout master
git pull
cd ../..

