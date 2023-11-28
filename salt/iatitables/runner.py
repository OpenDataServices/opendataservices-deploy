import iatidata
import os

os.chdir("{{ dir }}")
os.environ["IATI_TABLES_SCHEMA"] = "iati"
os.environ["IATI_TABLES_OUTPUT"] = "{{ dir }}"
os.environ["DATABASE_URL"] = "{{ db_url }}"

iatidata.run_all(processes={{ processes }})

