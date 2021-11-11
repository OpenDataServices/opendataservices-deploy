
{% from 'lib.sls' import apache  %}

include:
  - core
  - apache
  - letsencrypt

{% macro domainredirect(name, from_domain, to_url) %}

{% set extracontext %}
redirect_to: {{ to_url }}
{% endset %}

{{ apache('domain-redirects.conf',
    name=name+'.conf',
    servername=from_domain,
    extracontext=extracontext) }}

{% endmacro %}

{% for dr in pillar.domainredirects %}
{{ domainredirect(
    name='domain-redirect-'+ dr.name,
    from_domain=dr.from_domain,
    to_url=dr.to_url ) }}
{% endfor %}

