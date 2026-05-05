#!/bin/bash
# Har bir loyiha uchun alohida user va alohida database yaratadi.
# User nomi = DB nomi. User shu DB'ning egasi bo'ladi.
#
# Talab qilinadigan env'lar:
#   INIT_DATABASES         — vergul bilan ajratilgan loyiha nomlari (masalan: "familytree,portify")
#   DB_<NAME>_PASSWORD     — har bir nom uchun parol (masalan: DB_FAMILYTREE_PASSWORD)
set -e

if [ -z "$INIT_DATABASES" ]; then
  echo "INIT_DATABASES bo'sh, hech narsa yaratilmaydi"
  exit 0
fi

for db in $(echo "$INIT_DATABASES" | tr ',' ' '); do
  db=$(echo "$db" | xargs)
  [ -z "$db" ] && continue

  pass_var="DB_$(echo "$db" | tr '[:lower:]' '[:upper:]')_PASSWORD"
  pass="${!pass_var}"

  if [ -z "$pass" ]; then
    echo "ERROR: $pass_var o'rnatilmagan ($db uchun parol kerak)" >&2
    exit 1
  fi

  echo "Creating role and database: $db"
  psql -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    -v dbname="$db" \
    -v dbpass="$pass" <<-'EOSQL'
    SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'dbname', :'dbpass')
    WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'dbname')\gexec

    SELECT format('CREATE DATABASE %I OWNER %I', :'dbname', :'dbname')
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'dbname')\gexec
EOSQL
done
