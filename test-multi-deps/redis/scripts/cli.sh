#!/bin/bash
# Redis CLI access script

REDIS_HOST=${1:-localhost}
REDIS_PORT=${2:-6379}

echo "Connecting to Redis: $REDIS_HOST:$REDIS_PORT"
docker exec -it ${PROJECT_NAME:-app}_redis redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT"
