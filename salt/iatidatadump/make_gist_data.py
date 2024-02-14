import json

# META
with open("{{working_dir}}/metadata.json") as fp:
    data = {"files": {"metadata.json": {"content":fp.read()}}}
with open("{{working_dir}}/gist_metadata.json", "w") as fp:
    json.dump(data, fp)

# ERRORS
with open("{{working_dir}}/errors.txt") as fp:
    data = {"files": {"errors": {"content":fp.read()}}}
with open("{{working_dir}}/gist_errors.json", "w") as fp:
    json.dump(data, fp)



