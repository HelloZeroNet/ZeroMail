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
    try:
        content = json.load(open(root + "/users/" + dirname + "/content.json"))
        contents.append([content["modified"], dirname])
    except Exception, err:
        raw_input("Error load: %s" % err)


# Delete oldest 20
deleted = 0
for modified, dirname in sorted(contents):
    days_old = (time.time() - modified) / (60 * 60 * 24)
    if days_old < 30:
        continue
    if not os.path.isfile(root + "/users/" + dirname + "/data.json"):
        size = 0
    else:
        size = float(os.path.getsize(root + "/users/" + dirname + "/data.json")) / 1024
    print " - Deleting messages from %s (%.0f days old, %.2fkb)" % (dirname, days_old, size)
    cert_user_id = json.load(open(root + "/users/" + dirname + "/content.json"))["cert_user_id"]
    # Load publickey from data.json
    try:
        publickey = json.load(open(root + "/users/" + dirname + "/data.json"))["publickey"]
    except Exception, err:
        publickey = json.load(open(root + "/users/" + dirname + "/content.json"))["publickey"]

    # Insert publickey to archived.json
    archived = json.load(open(root + "/archived.json"))
    archived[dirname] = {"publickey": publickey, "cert_user_id": cert_user_id}
    json.dump(archived, open(root + "/archived.json", "w"), indent=2)

    # Insert dirname to archived dirnames
    users_content = json.load(open(root + "/users/content.json"))
    users_content["user_contents"]["archived"][dirname] = int(time.time())
    json.dump(users_content, open(root + "/users/content.json", "w"), indent=2)

    # Delete user files
    try:
        os.unlink(root + "/users/" + dirname + "/content.json")
    except Exception, err:
        print "Error deleting content.json", err
    try:
        os.unlink(root + "/users/" + dirname + "/data.json")
    except Exception, err:
        print "Error deleting data.json", err
    try:
        os.rmdir(root + "/users/" + dirname)
    except Exception, err:
        print "Error deleting dir", err

    deleted += 1
    if deleted > 100:
        break
cmd = "zeronet.py %s siteSign %s %s --inner_path data/users/%s/content.json --publish" % (" ".join(extra_params), site_address, site_privatekey, dirname)
#os.system(cmd)
print cmd