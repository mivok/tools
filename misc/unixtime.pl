#!/usr/bin/env perl -l
# Convert unix timestamps to local time
print scalar localtime @ARGV[0];
