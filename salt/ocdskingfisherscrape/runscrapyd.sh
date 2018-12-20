#!/bin/bash

set -e
cd {{ scrapyddir }}
source .ve/bin/activate
scrapyd
