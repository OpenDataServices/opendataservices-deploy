# Add our code as a Python Path
import sys
sys.path.insert(0,'/home/ocdsext/explorer/')

# Call our app!
from extension_explorer.views import app as application

