#!/bin/bash
set -e

echo "--------------------- DEPLOY"
git checkout main
git pull

echo "--------------------- PILLAR / PRIVATE"
cd pillar/private
git checkout main
git pull
cd ../..

echo "--------------------- SALT / PRIVATE"
cd salt/private
git checkout main
git pull
cd ../..

