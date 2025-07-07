#!/bin/bash
# This script prints a summary of the current firewalld configuration.
# It shows active zones, along with what is allowed in each zone, filering
# out information that isn't useful.

firewall-cmd --list-all-zones |
    awk '
        BEGIN {
            in_active_zone = 0
            stored_fieldname = ""
        }

        /^\S/ {
            # Check if the zone is active or default
            # The line looks like this: home (default, active)
            # or like this: home (active)
            # or like this: home (default)
            # or like this: home
            # Do a regex match on $0 to find "active" or "default" inside
            # parentheses
            if ($0 ~ /\(.*active.*\)/ || $0 ~ /\(.*default.*\)/) {
                in_active_zone = 1
                print
            }
        }

        /^$/ {
            if (in_active_zone) {
                # Print a blank line between active zones
                print ""
            }
            in_active_zone = 0
        }

        /^ / {
            # Skip non-active zones
            if (!in_active_zone) { next }
            # "forward-ports" and "rich rules" print their data on the following
            # lines, so we need to store the field name and only print it
            # when we encounter the next line that doesnt end with ": "
            if ($0 ~ /^  (forward-ports|rich rules):$/) {
                stored_fieldname = $0
                next
            }
            # Now check to see if we are on one of those lines (indented by at
            # least 4 spaces)
            if ($0 ~ /^    /) {
                if (stored_fieldname != "") {
                    print stored_fieldname
                    stored_fieldname = ""
                }
                print
                next
            }
            # Finally, print lines that dont end in ": " (i.e. that have data)
            if ($0 !~ /: $/) {
                print
            }
        }
    '
