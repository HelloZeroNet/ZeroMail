import json
import os
import time
import sys


root = os.path.dirname(__file__)
site_address = sys.argv[1]
site_privatekey = sys.argv[2]
extra_params = sys.argv[3:]

contents = []
for dirname in os.listdir(root + "/users"):
    if not os.path.isdir(root + "/users/" + dirname):
        continue
    if not os.path.isfile(root + "/users/" + dirname + "/data.json"):
        continue
    content = json.load(open(root + "/users/" + dirname + "/content.json"))
    contents.append([content["modified"], dirname])


# Delete oldest 50
for modified, dirname in sorted(contents)[0:50]:
    days_old = (time.time() - modified) / (60 * 60 * 24)
    if days_old < 30:
        continue
    print " - Deleting messages from %s (%.0f days old)" % (dirname, days_old)
    # Load publickey from data.json
    publickey = json.load(open(root + "/users/" + dirname + "/data.json"))["publickey"]
    # Insert publickey to content.json
    content = json.load(open(root + "/users/" + dirname + "/content.json"))
    content["publickey"] = publickey
    json.dump(content, open(root + "/users/" + dirname + "/content.json", "w"), indent=2)
    # Delete  data.json
    os.unlink(root + "/users/" + dirname + "/data.json")
    cmd = "zeronet.py %s siteSign %s %s --inner_path data/users/%s/content.json --publish" % (" ".join(extra_params), site_address, site_privatekey, dirname)
    os.system(cmd)
    time.sleep(60)
