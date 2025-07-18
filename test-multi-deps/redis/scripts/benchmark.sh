#!/bin/bash
# Redis performance benchmark

REQUESTS=${1:-10000}
CLIENTS=${2:-50}

echo "Running Redis benchmark:"
echo "Requests: $REQUESTS"
echo "Concurrent clients: $CLIENTS"

docker exec ${PROJECT_NAME:-app}_redis redis-benchmark -n "$REQUESTS" -c "$CLIENTS"
