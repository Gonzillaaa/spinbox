#!/bin/bash
# Database backup script

set -e

# Configuration
DB_NAME="${POSTGRES_DB:-app}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup
echo "Creating backup of database $DB_NAME..."
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    --no-password --verbose --clean --if-exists --format=custom \
    --file="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.backup"

echo "Backup completed: $BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.backup"

# Keep only last 7 backups
find "$BACKUP_DIR" -name "${DB_NAME}_*.backup" -type f -mtime +7 -delete

echo "Old backups cleaned up"
