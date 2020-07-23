#!/usr/bin/env python3
# Takes in toml, dumps it out as json
# Run pip install toml to install the toml module
import json
import sys
import toml

if len(sys.argv) > 1:
    fh = open(sys.argv[1])
else:
    fh = sys.stdin

try:
    data = toml.load(fh)
except toml.TomlDecodeError as e:
    print(e)
    sys.exit(1)
print(json.dumps(data, indent=4, sort_keys=True))
