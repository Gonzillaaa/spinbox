#!/bin/bash
# Set up database from scratch

set -e

DB_NAME="${POSTGRES_DB:-app}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"

echo "Setting up database $DB_NAME..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do
    sleep 1
done

# Run initialization scripts
echo "Running initialization scripts..."
for script in ../init/*.sql; do
    if [ -f "$script" ]; then
        echo "Executing $script..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$script"
    fi
done

echo "Database setup completed successfully"
