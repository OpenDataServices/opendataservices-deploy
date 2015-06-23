import private_settings

DEBUG = False
TEMPLATE_DEBUG = DEBUG
ASSETS_DEBUG = DEBUG
ASSETS_AUTO_BUILD = DEBUG

# used in admin template so we know which site we're looking at
DEPLOY_ENV = "production"
DEPLOY_ENV_NAME = "Production Server"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',  # Add 'postgresql_psycopg2', 'postgresql', 'mysql', 'sqlite3' or 'oracle'.
        'NAME': '{{ repo }}',                      # Or path to database file if using sqlite3.
        'USER': '{{ repo[:16] }}',                      # Not used with sqlite3.
        'PASSWORD': private_settings.DB_PASSWORD,                  # Not used with sqlite3.
        'HOST': '127.0.0.1',                      # Set to empty string for localhost. Not used with sqlite3.
        'PORT': '',                      # Set to empty string for default. Not used with sqlite3.
        'OPTIONS': {
            "init_command": "SET storage_engine=INNODB",
        }
    }
}

# Commented out now that we're using raven/sentry instead
ADMINS = (
#    ('Ben Webb', 'ben.webb@opendataservices.coop'),
)

ALLOWED_HOSTS = [
    '.',
    'www.',
    '{{ pillar.domain_prefix }}ocds.opendataservices.coop',
    'ocds.open-contracting.org',
]

MANAGERS = ADMINS

DEFAULT_FROM_EMAIL = 'support@opendataservices.coop'
SERVER_EMAIL = 'code@opendataservices.coop'

{% if repo == 'opendatacomparison' %}
EXTRA_INSTALLED_APPS = ()
EXTRA_MIDDLEWARE_CLASSES = ()
LOGIN_URL = '/opendatacomparison/accounts/login/'
{% endif %}
