#!/bin/bash

# Note: This assumes for now that Postgres DB is setup already, outside of RATS. This test is targeted
# for now to run on Travis using their postgres services

set -e
current_dir="$(dirname "$0")"
POSTGRES_USER=postgres

psql -c 'drop database travis_logstash_db;' -U $POSTGRES_USER