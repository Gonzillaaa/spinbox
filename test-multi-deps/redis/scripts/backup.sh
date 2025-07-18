#!/bin/bash
# Redis backup script

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"

echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "Creating Redis backup..."
docker exec ${PROJECT_NAME:-app}_redis redis-cli bgsave
sleep 2

echo "Copying backup files..."
docker cp ${PROJECT_NAME:-app}_redis:/data/dump.rdb "$BACKUP_DIR/"
docker cp ${PROJECT_NAME:-app}_redis:/data/appendonly.aof "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup completed: $BACKUP_DIR"
