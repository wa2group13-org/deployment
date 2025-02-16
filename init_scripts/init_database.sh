#!/bin/bash

set -e
set -u

function create_database() {
  local DB=$1
  local PASSWORD=$2

  echo "Creating database and user '$DB'"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
CREATE USER $DB WITH ENCRYPTED PASSWORD '${PASSWORD}';
CREATE DATABASE $DB OWNER $DB;
EOSQL
}

function create_debezium() {
  local DB=$1
  local PASSWORD=$2

  echo "Creating user for debezium and altering the WriteAheadLog level."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
ALTER SYSTEM SET wal_level = logical;
SELECT pg_reload_conf();
CREATE USER $DB WITH REPLICATION ENCRYPTED PASSWORD '${PASSWORD}';
ALTER USER $DB WITH SUPERUSER;
EOSQL
}

function grant_debezium_permissions() {
  local DEBEZIUM_DB=$1
  local OTHER_DB=$2

  echo "Granting permission to debezium on ${OTHER_DB}"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
GRANT USAGE ON DATABASE ${OTHER_DB} SCHEMA public TO ${DEBEZIUM_DB};
EOSQL
}

if [ -z "$POSTGRES_MULTIPLE_DB" ]; then
  echo "POSTGRES_MULTIPLE_DB was not set!"
  exit 1
fi

if [ -z "$POSTGRES_MULTIPLE_PASSWORD" ]; then
  echo "POSTGRES_MULTIPLE_PASSWORD was not set!"
  exit 1
fi

readarray -td, DBS <<<"$POSTGRES_MULTIPLE_DB,"
readarray -td, PASSWORDS <<<"$POSTGRES_MULTIPLE_PASSWORD,"

if [ "${#DBS[@]}" -ne "${#PASSWORDS[@]}" ]; then
  echo "The length of POSTGRES_MULTIPLE_DB and POSTGRES_MULTIPLE_PASSWORD are not the same!"
  exit 1
fi;

echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DB"

for (( index=0; index<${#DBS[@]}-1; index++ )); do
  create_database "${DBS[@]:$index:1}" "${PASSWORDS[@]:$index:1}"
done

echo "Multiple database creation finished"

echo "Initializing database for debezium support"
create_debezium "$DEBEZIUM_DB" "$DEBEZIUM_PASSWORD"
echo "Debezium support initialization completed!"
