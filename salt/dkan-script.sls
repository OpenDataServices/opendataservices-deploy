# This is a salt formula to set up the dkan-script that provides
# a 360 Giving report website page
# ie. http://report.dev2.default.opendataservices.uk0.bigv.io

{% from 'lib.sls' import createuser, apache %}

# Create a user for this piece of work, see lib.sls for more info
{% set user = 'threesixty' %}
{{ createuser(user) }}

# Set up variables for the GitHub code
{% set repo = 'data-conversion' %}
{% set giturl = 'https://github.com/ThreeSixtyGiving/data-conversion.git' %}


include:
  - core
  - apache

# Download the repository from GitHub
{{ giturl }}:
  git.latest:
    - rev: master
    - target: /home/{{ user }}/{{ repo }}/
    - user: {{ user }}
    - require:
      - pkg: git



# Set up the Apache config using macro
{{ apache('dkan-script.conf') }}

# Create a logs directory to store output of cron jobs
/home/threesixty/logs:
  file.directory:
    - makedirs: True
    - user: threesixty
    - group: threesixty

# Set a cron job to run script once a day
cd /home/threesixty/data-conversion/scripts/ && ./generate_report.sh > /home/threesixty/logs/$(date +\%Y\%m\%d).log 2>&1:
  cron.present:
    - identifier: DKANCRON
    - user: threesixty
    - minute: 3
    - hour: 1

#Set a cron job to run every two hours to refresh the data at 360 Giving website
wget -O - http://threesixtygiving.org/get-involved/data/ >/dev/null 2>&1
  cron.present:
    - identifier: 360DKANCRON
    - user: threesixty
    - minute: '*/15'
