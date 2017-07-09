#!/usr/bin/env python
# Takes in toml, dumps it out as json
# Run pip install toml to install the toml module
import json
import sys
import toml

fh = open(sys.argv[1])
try:
    data = toml.load(fh)
except toml.TomlDecodeError, e:
    print e
    sys.exit(1)
print json.dumps(data, indent=4, sort_keys=True)
