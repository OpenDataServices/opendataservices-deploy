import iatidata
import os

os.chdir("{{ dir }}")
os.environ["IATI_TABLES_SCHEMA"] = "iati"
os.environ["IATI_TABLES_OUTPUT"] = "{{ dir }}"
os.environ["DATABASE_URL"] = "{{ db_url }}"
os.environ["IATI_TABLES_S3_DESTINATION"] = "-"

iatidata.run_all(processes={{ processes }})

