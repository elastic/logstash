#!/bin/bash

# Note: This assumes for now that Postgres DB is setup already, outside of RATS. This test is targeted
# for now to run on Travis using their postgres services

set -ex
current_dir="$(dirname "$0")"
POSTGRES_USER=postgres

source "$current_dir/helpers.sh"

curl -s -o $INSTALL_DIR/postgres-driver.jar "https://jdbc.postgresql.org/download/postgresql-9.4.1211.jar"
#psql -c 'create database travis_logstash_db;' -U $POSTGRES_USER
psql -U $POSTGRES_USER -d travis_logstash_db -a -f $current_dir/../fixtures/travis_postgres.sql

setup_install_dir