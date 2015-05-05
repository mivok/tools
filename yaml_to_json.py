#!/usr/bin/env python
# Takes in yaml, dumps it out as json
import json
import sys
import yaml

fh = open(sys.argv[1])
try:
    data = yaml.load(fh)
except yaml.error.YAMLError, e:
    print e
    sys.exit(1)
print json.dumps(data, indent=4, sort_keys=True)
