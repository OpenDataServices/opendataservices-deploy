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
