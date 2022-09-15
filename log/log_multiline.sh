#!/bin/bash
# Join multi-line log entries together, where successive lines are marked by
# whitespace.
#
# Usage: ./log_multiline.sh < multiline_log_file.txt
awk '
  # Store the first line in prev, so we dont print a blank line
  BEGIN { getline; prev = $0 };
  {
    # Set the output record separator to either \n or space depending on whether
    # the current line begins with whitespace. This means that when we print
    # anything out (such as the previous line which we do in the next step), we
    # will either include a newline or a space depending on whether we want to
    # join the lines or not.
    ORS=($0 ~ /^\S/)?"\n":" ";
    # Print the previous line (either with or without a newline appropriately)
    print prev;
    # Strip any whitespace at the beginning of the current line, before storing
    # it as the previous line. This just means we dont include any preceding
    # whitespace when joining lines together. If we skipped this line, all
    # whitespace would be included when the lines are joined.
    sub(/^\s+/, "", $0);
    # And store the current line as the previous one
    prev = $0
  };
  # At the end, we need to print out the previous line regardless (and with a
  # trailing newline, so we reset the value of ORS)
  END { ORS="\n"; print prev }
'
