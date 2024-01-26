#!/bin/bash

/home/{{ user }}/runner.sh > {{ logs_dir }}/$(date +\%Y\%m\%d-\%H\%M\%S).log 2>&1
