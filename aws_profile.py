#!/usr/bin/env python
# Reads a profile from ~/.aws/config and calls the command with
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY set correctly.
import ConfigParser
import os
import subprocess
import sys

c = ConfigParser.SafeConfigParser()
c.read(os.path.expanduser('~/.aws/credentials'))

section = sys.argv[1]
cmd = sys.argv[2:]

#if section != 'default':
#    section = 'profile %s' % section

os.environ['AWS_ACCESS_KEY_ID'] = c.get(section, 'aws_access_key_id')
os.environ['AWS_SECRET_ACCESS_KEY'] = c.get(section, 'aws_secret_access_key')
print os.environ['AWS_ACCESS_KEY_ID']
subprocess.call(' '.join(cmd), shell=True)
