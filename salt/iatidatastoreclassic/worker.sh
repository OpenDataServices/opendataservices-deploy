#!/bin/bash

set -e

source .ve/bin/activate
source env.sh
iati queue background
