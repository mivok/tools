#!/usr/bin/env -S perl -l
# Convert unix timestamps to local time
print scalar localtime @ARGV[0];
print scalar gmtime @ARGV[0];
