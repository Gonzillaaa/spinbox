#!/bin/bash
# Redis cache flush script

DATABASE=${1:-0}

echo "Flushing Redis database: $DATABASE"
if [[ "$DATABASE" == "all" ]]; then
    docker exec ${PROJECT_NAME:-app}_redis redis-cli flushall
    echo "All databases flushed"
else
    docker exec ${PROJECT_NAME:-app}_redis redis-cli -n "$DATABASE" flushdb
    echo "Database $DATABASE flushed"
fi
