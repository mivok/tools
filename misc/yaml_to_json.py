#!/usr/bin/env -S uv run
# /// script
# dependencies = ["pyyaml"]
# ///

# Takes in yaml, dumps it out as json
import json
import sys
import yaml

fh = open(sys.argv[1])
try:
    data = yaml.safe_load(fh)
except yaml.error.YAMLError as e:
    print(e)
    sys.exit(1)
print(json.dumps(data, indent=4, sort_keys=True))
