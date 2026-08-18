#!/bin/bash
set -e

echo "[db-setup] Installing gems..."
bundle install

echo "[db-setup] Waiting for PostgreSQL to be ready..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do
  echo "[db-setup] PostgreSQL is not ready yet. Retrying in 1 second..."
  sleep 1
done
echo "[db-setup] PostgreSQL is ready."

echo "[db-setup] Running database prepare..."
bundle exec rails db:prepare
echo "[db-setup] Database prepare completed."

echo "[db-setup] Running seeds..."
bundle exec rails db:seed
echo "[db-setup] Seeds completed."

echo "[db-setup] Starting Rails server..."
exec "$@"
