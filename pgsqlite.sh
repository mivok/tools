#!/bin/bash
# Throw away postgres instance - feels like sqlite
# Quickly starts a postgres server and client for you to play with
# To use on a mac: brew install postgres
DBDIR="$1"
DBNAME="$2"
if [[ -z $DBDIR ]]; then
    DBDIR="./pgsql"
fi
if [[ -z $DBNAME ]]; then
    DBNAME="$(whoami)"
fi

# Make the db if it doesn't exist
if [[ ! -d $DBDIR ]]; then
    initdb "$DBDIR" -E utf8
fi

# Start the DB
pg_ctl -D "$DBDIR" -l $DBDIR/postgresql.log start

# Wait for the db to start
echo -n "Waiting for the DB to start"
for ((COUNT=0; COUNT<10; COUNT++)); do
    echo -n "."
    if psql -l >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done
echo
if [[ "$COUNT" == "$TRIES" ]]; then
    echo "DB failed to start"
    exit 1
fi

# Make the DB if it doesn't exist
if ! psql -l | egrep "^ $DBNAME  *\\|" >/dev/null 2>&1; then
    createdb "$DBNAME"
fi

# Start the postgres client
psql "$DBNAME"

# Stop the DB
pg_ctl -D ./pgsql stop

echo "Database is in $DBDIR"
echo "To remove it, run rm -rf $DBDIR"
