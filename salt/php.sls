# Currently this sls file is for otherwise unfulfilled php related deps.


{% if grains['lsb_distrib_release']=='14.04' %}
  {% set phpver='5' %}
{% else %}
  {% set phpver='7.0' %}
{% endif %}


libapache2-mod-php{{ phpver }}:
  pkg.installed:
    - watch_in:
      - service: apache2
