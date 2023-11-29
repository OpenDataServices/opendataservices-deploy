#!/bin/bash

{{ app_dir }}/runner.sh > {{ logs_dir }}/$(date +\%Y\%m\%d-\%H\%M\%S).log 2>&1
