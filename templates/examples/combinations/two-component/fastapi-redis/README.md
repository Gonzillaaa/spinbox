# FastAPI + Redis Integration

Complete examples for building high-performance APIs with caching and real-time features using FastAPI and Redis.

## Overview

This combination demonstrates how to create scalable, high-performance APIs using:
- **FastAPI**: Modern, fast web framework for building APIs
- **Redis**: In-memory data store for caching, sessions, and real-time messaging
- **redis-py**: Python client for Redis
- **aioredis**: Async Redis client for FastAPI

## Prerequisites

1. **Redis Server**: Running Redis instance
2. **Dependencies**:
   ```bash
   pip install fastapi uvicorn redis aioredis python-dotenv pydantic
   ```

## Redis Setup

### Docker Redis (Recommended)
```bash
docker run --name redis-server \
  -p 6379:6379 \
  -d redis:7-alpine
```

### Environment Setup
Create `.env` file:
```env
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=
REDIS_URL=redis://localhost:6379/0

# FastAPI Configuration
SECRET_KEY=your-secret-key-here
DEBUG=True

# Cache Configuration
CACHE_TTL=300
SESSION_TTL=1800
```

## Examples Included

### `example-caching-api.py`
Comprehensive caching implementation with Redis.

**Features:**
- Response caching
- Database query caching
- Cache invalidation
- Cache warming
- TTL management

**Endpoints:**
- `GET /cache/stats` - Cache statistics
- `GET /users/{user_id}` - Cached user data
- `POST /cache/clear` - Clear cache
- `GET /cache/warm` - Warm cache

### `example-session-api.py`
Session management with Redis backend.

**Features:**
- User session storage
- Session-based authentication
- Session timeout handling
- Multi-device support
- Session analytics

**Endpoints:**
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `GET /auth/session` - Get session info
- `GET /auth/sessions` - List user sessions

### `example-realtime-api.py`
Real-time features with Redis pub/sub.

**Features:**
- WebSocket connections
- Real-time messaging
- Channel subscriptions
- Message broadcasting
- Connection management

**Endpoints:**
- `WS /ws/chat/{room}` - Chat room WebSocket
- `POST /chat/message` - Send message
- `GET /chat/rooms` - List active rooms
- `GET /chat/history` - Message history

## Usage Examples

### 1. Cache Response Data
```bash
curl "http://localhost:8000/users/1"
# First request: Cache miss, loads from database
# Subsequent requests: Cache hit, returns cached data
```

### 2. User Session Management
```bash
# Login
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "user1", "password": "password123"}'

# Access protected endpoint
curl "http://localhost:8000/auth/session" \
  -H "Authorization: Bearer <session_token>"
```

### 3. Real-time Chat
```bash
# Connect to WebSocket
wscat -c ws://localhost:8000/ws/chat/room1

# Send message via HTTP
curl -X POST "http://localhost:8000/chat/message" \
  -H "Content-Type: application/json" \
  -d '{"room": "room1", "message": "Hello World!"}'
```

### 4. Cache Management
```bash
# Get cache statistics
curl "http://localhost:8000/cache/stats"

# Clear specific cache
curl -X POST "http://localhost:8000/cache/clear" \
  -H "Content-Type: application/json" \
  -d '{"pattern": "user:*"}'
```

### 5. Rate Limiting
```bash
# Test rate limiting
for i in {1..10}; do
  curl "http://localhost:8000/api/limited-endpoint"
done
```

## Redis Patterns

### 1. Caching Layer
```python
import redis
import json
from typing import Optional, Any

class CacheManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.default_ttl = 300
    
    def get(self, key: str) -> Optional[Any]:
        data = self.redis.get(key)
        if data:
            return json.loads(data)
        return None
    
    def set(self, key: str, value: Any, ttl: int = None):
        ttl = ttl or self.default_ttl
        self.redis.setex(key, ttl, json.dumps(value))
    
    def delete(self, key: str):
        self.redis.delete(key)
```

### 2. Session Management
```python
class SessionManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.session_prefix = "session:"
        self.user_sessions_prefix = "user_sessions:"
    
    def create_session(self, user_id: str, session_data: dict) -> str:
        session_id = str(uuid.uuid4())
        session_key = f"{self.session_prefix}{session_id}"
        
        # Store session data
        self.redis.hmset(session_key, session_data)
        self.redis.expire(session_key, 1800)  # 30 minutes
        
        # Track user sessions
        user_sessions_key = f"{self.user_sessions_prefix}{user_id}"
        self.redis.sadd(user_sessions_key, session_id)
        
        return session_id
```

### 3. Real-time Messaging
```python
class MessageBroker:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    def publish(self, channel: str, message: dict):
        self.redis.publish(channel, json.dumps(message))
    
    def subscribe(self, channels: List[str]):
        pubsub = self.redis.pubsub()
        pubsub.subscribe(channels)
        return pubsub
```

### 4. Rate Limiting
```python
class RateLimiter:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    def is_allowed(self, key: str, limit: int, window: int) -> bool:
        current = self.redis.get(key)
        if current is None:
            self.redis.setex(key, window, 1)
            return True
        
        if int(current) < limit:
            self.redis.incr(key)
            return True
        
        return False
```

## Advanced Features

### 1. Distributed Locking
```python
import time
import uuid

class DistributedLock:
    def __init__(self, redis_client: redis.Redis, key: str, timeout: int = 10):
        self.redis = redis_client
        self.key = f"lock:{key}"
        self.timeout = timeout
        self.identifier = str(uuid.uuid4())
    
    def acquire(self) -> bool:
        end_time = time.time() + self.timeout
        
        while time.time() < end_time:
            if self.redis.set(self.key, self.identifier, nx=True, ex=self.timeout):
                return True
            time.sleep(0.001)
        
        return False
    
    def release(self) -> bool:
        script = """
        if redis.call('GET', KEYS[1]) == ARGV[1] then
            return redis.call('DEL', KEYS[1])
        else
            return 0
        end
        """
        return bool(self.redis.eval(script, 1, self.key, self.identifier))
```

### 2. Task Queue
```python
class TaskQueue:
    def __init__(self, redis_client: redis.Redis, queue_name: str):
        self.redis = redis_client
        self.queue_name = queue_name
    
    def enqueue(self, task_data: dict):
        self.redis.lpush(self.queue_name, json.dumps(task_data))
    
    def dequeue(self, timeout: int = 0) -> Optional[dict]:
        result = self.redis.brpop(self.queue_name, timeout)
        if result:
            return json.loads(result[1])
        return None
```

### 3. Leaderboard
```python
class Leaderboard:
    def __init__(self, redis_client: redis.Redis, name: str):
        self.redis = redis_client
        self.key = f"leaderboard:{name}"
    
    def add_score(self, user_id: str, score: float):
        self.redis.zadd(self.key, {user_id: score})
    
    def get_top(self, count: int = 10) -> List[tuple]:
        return self.redis.zrevrange(self.key, 0, count - 1, withscores=True)
    
    def get_user_rank(self, user_id: str) -> Optional[int]:
        rank = self.redis.zrevrank(self.key, user_id)
        return rank + 1 if rank is not None else None
```

## Performance Optimization

### 1. Connection Pooling
```python
import redis.connection

# Configure connection pool
pool = redis.ConnectionPool(
    host='localhost',
    port=6379,
    db=0,
    max_connections=20,
    socket_timeout=5,
    socket_connect_timeout=5,
    retry_on_timeout=True
)

redis_client = redis.Redis(connection_pool=pool)
```

### 2. Pipeline Operations
```python
def batch_operations(redis_client: redis.Redis, operations: List[tuple]):
    pipe = redis_client.pipeline()
    
    for op_type, key, value in operations:
        if op_type == 'set':
            pipe.set(key, value)
        elif op_type == 'get':
            pipe.get(key)
        elif op_type == 'delete':
            pipe.delete(key)
    
    return pipe.execute()
```

### 3. Async Operations
```python
import aioredis

async def async_cache_operations():
    redis = await aioredis.from_url("redis://localhost")
    
    # Async operations
    await redis.set("key", "value")
    value = await redis.get("key")
    
    await redis.close()
```

## Security Considerations

### 1. Authentication
```python
# Redis AUTH
redis_client = redis.Redis(
    host='localhost',
    port=6379,
    password='your-redis-password'
)
```

### 2. SSL/TLS
```python
# Redis with SSL
redis_client = redis.Redis(
    host='localhost',
    port=6380,
    ssl=True,
    ssl_cert_reqs=None
)
```

### 3. Access Control
```python
# Validate cache keys
def validate_cache_key(key: str) -> bool:
    allowed_prefixes = ['user:', 'session:', 'cache:']
    return any(key.startswith(prefix) for prefix in allowed_prefixes)
```

## Testing

### 1. Redis Mock for Testing
```python
import fakeredis
import pytest

@pytest.fixture
def redis_client():
    return fakeredis.FakeRedis()

def test_cache_operations(redis_client):
    cache = CacheManager(redis_client)
    
    # Test set and get
    cache.set("test_key", {"data": "value"})
    result = cache.get("test_key")
    
    assert result == {"data": "value"}
```

### 2. Integration Tests
```python
def test_session_management(client, redis_client):
    # Test login
    response = client.post("/auth/login", json={
        "username": "testuser",
        "password": "testpass"
    })
    
    assert response.status_code == 200
    session_token = response.json()["session_token"]
    
    # Test authenticated request
    response = client.get("/auth/session", headers={
        "Authorization": f"Bearer {session_token}"
    })
    
    assert response.status_code == 200
```

## Deployment

### 1. Redis Configuration
```bash
# redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

### 2. Docker Compose
```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
  
  app:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/0

volumes:
  redis_data:
```

### 3. Health Checks
```python
@app.get("/health")
async def health_check():
    try:
        # Test Redis connection
        redis_client.ping()
        return {"status": "healthy", "redis": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "redis": "disconnected", "error": str(e)}
```

## Monitoring

### 1. Redis Metrics
```python
def get_redis_info(redis_client: redis.Redis) -> dict:
    info = redis_client.info()
    return {
        "used_memory": info.get("used_memory_human"),
        "connected_clients": info.get("connected_clients"),
        "keyspace_hits": info.get("keyspace_hits"),
        "keyspace_misses": info.get("keyspace_misses"),
        "ops_per_sec": info.get("instantaneous_ops_per_sec")
    }
```

### 2. Cache Hit Rate
```python
class CacheMetrics:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.hits = 0
        self.misses = 0
    
    def record_hit(self):
        self.hits += 1
    
    def record_miss(self):
        self.misses += 1
    
    def get_hit_rate(self) -> float:
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0
```

## Common Issues and Solutions

### 1. Memory Issues
**Problem**: Redis running out of memory
**Solution**: Configure maxmemory and eviction policies

### 2. Connection Issues
**Problem**: Connection timeouts
**Solution**: Configure connection pooling and timeouts

### 3. Key Expiration
**Problem**: Keys expiring unexpectedly
**Solution**: Monitor TTL and implement proper key management

### 4. Performance Issues
**Problem**: Slow Redis operations
**Solution**: Use pipelining and optimize data structures

## Next Steps

1. **Start with caching**: Try `example-caching-api.py`
2. **Add sessions**: Implement `example-session-api.py`
3. **Real-time features**: Use `example-realtime-api.py`
4. **Scale up**: Add Redis Cluster and monitoring
5. **Deploy**: Use Docker Compose and Redis configurations

## Resources

- **Redis Documentation**: https://redis.io/docs/
- **redis-py Documentation**: https://redis-py.readthedocs.io/
- **aioredis Documentation**: https://aioredis.readthedocs.io/
- **FastAPI Background Tasks**: https://fastapi.tiangolo.com/tutorial/background-tasks/