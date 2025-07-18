#!/bin/bash
# Redis monitoring script

echo "Redis Server Status:"
docker exec ${PROJECT_NAME:-app}_redis redis-cli info server

echo -e "\nRedis Memory Usage:"
docker exec ${PROJECT_NAME:-app}_redis redis-cli info memory

echo -e "\nRedis Statistics:"
docker exec ${PROJECT_NAME:-app}_redis redis-cli info stats

echo -e "\nRedis Keyspace:"
docker exec ${PROJECT_NAME:-app}_redis redis-cli info keyspace

echo -e "\nRedis Connected Clients:"
docker exec ${PROJECT_NAME:-app}_redis redis-cli info clients
