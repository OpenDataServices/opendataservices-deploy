#!/bin/bash

# See https://github.com/codeforIATI/iati-tables/issues/11
# The template has hardcoded links
# So AFTER we check out the source file but BEFORE we build the website .... we change them!

set -e

cd {{ template_dir }}

sed -i 's,https://iati.fra1.digitaloceanspaces.com,{{ data_url }},' Home.vue
sed -i 's,https://datasette.codeforiati.org,{{ datasette_url }},' Home.vue



