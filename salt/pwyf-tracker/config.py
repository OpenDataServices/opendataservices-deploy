from os.path import abspath, dirname, join, realpath
from urllib.parse import urlparse


SQLALCHEMY_TRACK_MODIFICATIONS = False
SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2:///pwyf_tracker'
database_uri_parsed = urlparse(SQLALCHEMY_DATABASE_URI)
DATABASE_INFO = {
    "user": database_uri_parsed.username,
    "password": database_uri_parsed.password,
    "database": database_uri_parsed.path[1:],
    "host": database_uri_parsed.hostname,
    "port": database_uri_parsed.port,
}
SAMPLING_DB_FILENAME = join(realpath(dirname(__file__)), 'sample_work.db')

SECRET_KEY = "{{ secret_key }}"

INDICATOR_GROUP = u"2024index"

CODELIST_API = u"https://reference.iatistandard.org/{version}/codelists/downloads/clv2"

ORG_FREQUENCY_API_URL = "http://publishingstats.iatistandard.org/timeliness_frequency.csv"
IATIUPDATES_URL = "http://tracker.publishwhatyoufund.org/iatiupdates/api/package/hash/"

# if this is set to False, don't be surprised if your database
# becomes ludicrously huge. Heed my words.
REMOVE_RESULTS = True

INTRO_HTML = 'Data collection for the <a href="https://www.publishwhatyoufund.org/2023/08/who-will-be-assessed-in-the-2024-aid-transparency-index/">2024 Aid Transparency Index</a> has now started. We will release more detailed information in May 2024 when the Aid Transparency Index will be launched. Results and analysis for previous years is available in the <a href="https://www.publishwhatyoufund.org/the-index/2022/" target="_blank">2022 Index</a>.'

ATI_YEAR = '2024'
PREVIOUS_ATI_YEAR = '2022'

basedir = dirname(abspath(__file__))
IATI_DATA_PATH = join(basedir, 'data')
IATI_RESULT_PATH = join(basedir, 'results')

# For local development, the creation of the admin user can be automated by using these config variables
# Use with the --admin-from-config flag of the `flask setup` command
# APP_ADMIN_USERNAME = "admin"
# APP_ADMIN_PASSWORD = "admin"

