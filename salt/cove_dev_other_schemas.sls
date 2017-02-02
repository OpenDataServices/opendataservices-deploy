{% from 'cove.sls' import cove, giturl, user %}

include:
  - cove


{{ cove(
    name='cove-ppp',
    giturl=giturl,
    branch='544-ppp',
    djangodir='/home/'+user+'/cove-ppp/',
    uwsgi_port=3139,
    schema_url_ocds='http://standard.open-contracting.org/ppp-extension/en/',
    user=user) }}

{{ cove(
    name='527-support-deprecation-warnings',
    giturl=giturl,
    branch='527-support-deprecation-warnings',
    djangodir='/home/'+user+'/527-support-deprecation-warnings/',
    uwsgi_port=3140,
    schema_url_ocds='http://527-support-deprecation-warnings.dev.cove.opendataservices.coop/static/example_deprecated_schema/',
    user=user) }}
