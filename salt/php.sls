# Currently this sls file is for otherwise unfulfilled php related deps.


{% if grains['lsb_distrib_release']=='14.04' %}
  {% set phpver='5' %}
{% elif grains['lsb_distrib_release']=='16.04' %}
  {% set phpver='7.0' %}
{% elif grains['lsb_distrib_release']=='18.04' %}
  {% set phpver='7.2' %}
{% elif grains['lsb_distrib_release']=='20.04' %}
  {% set phpver='7.4' %}
{% else %}
  {% set phpver='wtf' %}
{% endif %}


libapache2-mod-php{{ phpver }}:
  pkg.installed:
    - watch_in:
      - service: apache2
