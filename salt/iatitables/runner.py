import iatidata
import os

os.chdir("{{ dir }}")

iatidata.run_all(processes={{ processes }})

