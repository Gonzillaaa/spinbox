# Redis Component Examples

This directory contains working examples for Redis caching and data operations that demonstrate best practices and common patterns.

## 📋 Available Examples

### Core Examples
- **example-caching.js** - Caching patterns and strategies
- **example-sessions.js** - Session management with Redis
- **example-pub-sub.js** - Real-time messaging with pub/sub
- **example-rate-limiting.js** - Rate limiting implementation
- **example-data-structures.js** - Redis data structures usage

## 🚀 Setup Instructions

1. **Ensure Redis is running:**
   ```bash
   docker-compose up -d redis
   ```

2. **Install Redis client:**
   ```bash
   npm install redis
   ```

3. **Test connection:**
   ```bash
   redis-cli ping
   ```

4. **Run examples:**
   ```bash
   node example-caching.js
   node example-sessions.js
   node example-pub-sub.js
   ```

## 📖 Example Details

### example-caching.js
Demonstrates:
- Basic caching patterns
- Cache invalidation strategies
- TTL (Time To Live) management
- Cache-aside pattern
- Write-through caching
- Performance optimization

### example-sessions.js
Demonstrates:
- User session storage
- Session expiration
- Session data management
- Security best practices
- Cleanup strategies

### example-pub-sub.js
Demonstrates:
- Real-time messaging
- Channel subscriptions
- Message broadcasting
- Event-driven architecture
- Pattern matching

### example-rate-limiting.js
Demonstrates:
- Request rate limiting
- Sliding window algorithm
- Token bucket implementation
- IP-based limiting
- User-based limiting

### example-data-structures.js
Demonstrates:
- Lists, Sets, Sorted Sets
- Hashes and Strings
- Geospatial data
- HyperLogLog
- Streams

## 🔧 Integration with FastAPI

These examples can be integrated with FastAPI backends for:
- API response caching
- Session management
- Real-time features
- Rate limiting middleware
- Background task queues

## 📝 Notes

- Examples use Redis 7.0+ features
- Includes connection pooling
- Error handling and retry logic
- Performance monitoring
- Memory optimization techniques