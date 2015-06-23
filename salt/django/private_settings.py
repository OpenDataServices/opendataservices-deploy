ANNOTATEIT_KEY = ''
ANNOTATEIT_SECRET = ''
DB_PASSWORD = '{{ pillar[repo].mysql_password }}'
GITHUB_API_CLIENT_ID = ''
GITHUB_API_CLIENT_SECRET = ''
SECRET_KEY = '{{ pillar[repo].secret_key }}'
SENDGRID_PASSWORD = ''
SENDGRID_USERNAME = ''
SITE_UNIQUE_ID = ''
RAVEN_CONFIG = {
    'dsn': '{{ pillar[repo].sentry_dsn }}'
}
{% if repo == 'opendatacomparison' %}
SOCIAL_AUTH_TWITTER_KEY = '{{pillar.opendatacomparison.social_auth.twitter.key}}'
SOCIAL_AUTH_TWITTER_SECRET = '{{pillar.opendatacomparison.social_auth.twitter.secret}}' 
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = '{{pillar.opendatacomparison.social_auth.google.key}}'
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = '{{pillar.opendatacomparison.social_auth.google.secret}}'
{% else %}
SOCIAL_AUTH_TWITTER_KEY = ''
SOCIAL_AUTH_TWITTER_SECRET = ''
SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = ''
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = ''
{% endif %}
