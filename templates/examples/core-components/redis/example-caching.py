#!/usr/bin/env python3
"""
Redis Caching Example (Python)

This example demonstrates how to use Redis for caching in Python applications
with proper error handling and connection management.
"""

import os
import sys
import json
import time
from typing import Any, Optional, Dict, List
from functools import wraps
import redis
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Load environment variables
load_dotenv()

class RedisCache:
    """Redis caching client with connection pooling."""
    
    def __init__(self, 
                 host: str = None,
                 port: int = None,
                 db: int = None,
                 password: str = None,
                 max_connections: int = 10):
        """Initialize Redis client with connection pooling."""
        
        # Get configuration from environment variables
        self.host = host or os.getenv("REDIS_HOST", "localhost")
        self.port = port or int(os.getenv("REDIS_PORT", "6379"))
        self.db = db or int(os.getenv("REDIS_DB", "0"))
        self.password = password or os.getenv("REDIS_PASSWORD")
        
        # Create connection pool
        self.pool = redis.ConnectionPool(
            host=self.host,
            port=self.port,
            db=self.db,
            password=self.password,
            max_connections=max_connections,
            decode_responses=True  # Automatically decode responses to strings
        )
        
        # Create Redis client
        self.client = redis.Redis(connection_pool=self.pool)
        
        # Test connection
        try:
            self.client.ping()
            print(f"✅ Connected to Redis at {self.host}:{self.port}")
        except redis.ConnectionError as e:
            print(f"❌ Failed to connect to Redis: {e}")
            raise
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set a value in Redis with optional TTL."""
        try:
            # Serialize complex objects to JSON
            if isinstance(value, (dict, list)):
                value = json.dumps(value)
            
            # Set with TTL if provided
            if ttl:
                result = self.client.setex(key, ttl, value)
            else:
                result = self.client.set(key, value)
            
            return bool(result)
            
        except Exception as e:
            print(f"❌ Error setting cache key {key}: {e}")
            return False
    
    def get(self, key: str) -> Optional[Any]:
        """Get a value from Redis."""
        try:
            value = self.client.get(key)
            
            if value is None:
                return None
            
            # Try to deserialize JSON
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
                
        except Exception as e:
            print(f"❌ Error getting cache key {key}: {e}")
            return None
    
    def exists(self, key: str) -> bool:
        """Check if a key exists in Redis."""
        try:
            return bool(self.client.exists(key))
        except Exception as e:
            print(f"❌ Error checking existence of key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete a key from Redis."""
        try:
            result = self.client.delete(key)
            return bool(result)
        except Exception as e:
            print(f"❌ Error deleting key {key}: {e}")
            return False
    
    def increment(self, key: str, amount: int = 1) -> Optional[int]:
        """Increment a numeric value in Redis."""
        try:
            return self.client.incr(key, amount)
        except Exception as e:
            print(f"❌ Error incrementing key {key}: {e}")
            return None
    
    def expire(self, key: str, ttl: int) -> bool:
        """Set TTL for an existing key."""
        try:
            return bool(self.client.expire(key, ttl))
        except Exception as e:
            print(f"❌ Error setting TTL for key {key}: {e}")
            return False
    
    def ttl(self, key: str) -> Optional[int]:
        """Get TTL for a key."""
        try:
            ttl = self.client.ttl(key)
            return ttl if ttl >= 0 else None
        except Exception as e:
            print(f"❌ Error getting TTL for key {key}: {e}")
            return None
    
    def flush_db(self) -> bool:
        """Clear all keys in the current database."""
        try:
            return bool(self.client.flushdb())
        except Exception as e:
            print(f"❌ Error flushing database: {e}")
            return False
    
    def get_info(self) -> Dict[str, Any]:
        """Get Redis server information."""
        try:
            info = self.client.info()
            return {
                "redis_version": info.get("redis_version"),
                "used_memory_human": info.get("used_memory_human"),
                "connected_clients": info.get("connected_clients"),
                "total_commands_processed": info.get("total_commands_processed"),
                "keyspace_hits": info.get("keyspace_hits"),
                "keyspace_misses": info.get("keyspace_misses")
            }
        except Exception as e:
            print(f"❌ Error getting Redis info: {e}")
            return {}

def cache_decorator(ttl: int = 300, prefix: str = "cache"):
    """Decorator to cache function results."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Create cache key
            cache_key = f"{prefix}:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # Try to get from cache
            cache = RedisCache()
            cached_result = cache.get(cache_key)
            
            if cached_result is not None:
                print(f"🚀 Cache hit for {func.__name__}")
                return cached_result
            
            # Execute function and cache result
            print(f"⏳ Cache miss for {func.__name__}, executing...")
            result = func(*args, **kwargs)
            
            # Cache the result
            cache.set(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator

class CacheDemo:
    """Demonstration of Redis caching functionality."""
    
    def __init__(self):
        """Initialize the cache demo."""
        self.cache = RedisCache()
    
    @cache_decorator(ttl=60, prefix="demo")
    def expensive_operation(self, n: int) -> Dict[str, Any]:
        """Simulate an expensive operation."""
        print(f"Performing expensive calculation for n={n}...")
        time.sleep(2)  # Simulate work
        
        result = {
            "input": n,
            "fibonacci": self._fibonacci(n),
            "timestamp": datetime.now().isoformat(),
            "computed": True
        }
        
        return result
    
    def _fibonacci(self, n: int) -> int:
        """Calculate Fibonacci number (inefficient for demo)."""
        if n <= 1:
            return n
        return self._fibonacci(n-1) + self._fibonacci(n-2)
    
    def user_session_example(self):
        """Demonstrate user session caching."""
        print("\n📝 User Session Caching Example")
        print("-" * 40)
        
        # Create user session
        user_id = "user123"
        session_data = {
            "user_id": user_id,
            "username": "john_doe",
            "login_time": datetime.now().isoformat(),
            "permissions": ["read", "write"],
            "preferences": {
                "theme": "dark",
                "language": "en"
            }
        }
        
        session_key = f"session:{user_id}"
        
        # Store session with 1 hour TTL
        if self.cache.set(session_key, session_data, ttl=3600):
            print(f"✅ Session created for user {user_id}")
        
        # Retrieve session
        retrieved_session = self.cache.get(session_key)
        if retrieved_session:
            print(f"👤 Retrieved session: {retrieved_session['username']}")
            print(f"⏰ Session TTL: {self.cache.ttl(session_key)} seconds")
        
        # Update session
        session_data["last_activity"] = datetime.now().isoformat()
        self.cache.set(session_key, session_data, ttl=3600)
        print("🔄 Session updated with last activity")
        
        return session_key
    
    def counter_example(self):
        """Demonstrate counter functionality."""
        print("\n🔢 Counter Example")
        print("-" * 40)
        
        counter_key = "page_views"
        
        # Initialize counter
        if not self.cache.exists(counter_key):
            self.cache.set(counter_key, 0)
        
        # Increment counter
        for i in range(5):
            views = self.cache.increment(counter_key)
            print(f"📊 Page views: {views}")
            time.sleep(0.5)
        
        return counter_key
    
    def rate_limiting_example(self):
        """Demonstrate rate limiting."""
        print("\n⚡ Rate Limiting Example")
        print("-" * 40)
        
        user_id = "user456"
        rate_key = f"rate_limit:{user_id}"
        
        # Allow 5 requests per minute
        max_requests = 5
        window = 60  # seconds
        
        def make_request():
            current_requests = self.cache.get(rate_key) or 0
            
            if current_requests >= max_requests:
                ttl = self.cache.ttl(rate_key)
                print(f"❌ Rate limit exceeded. Try again in {ttl} seconds")
                return False
            
            # Increment request count
            if current_requests == 0:
                self.cache.set(rate_key, 1, ttl=window)
            else:
                self.cache.increment(rate_key)
            
            current_requests += 1
            print(f"✅ Request allowed ({current_requests}/{max_requests})")
            return True
        
        # Simulate requests
        for i in range(7):
            make_request()
            time.sleep(0.5)
        
        return rate_key
    
    def cleanup_example_data(self):
        """Clean up example data."""
        print("\n🧹 Cleaning up example data...")
        keys_to_delete = [
            "session:user123",
            "page_views",
            "rate_limit:user456"
        ]
        
        for key in keys_to_delete:
            if self.cache.exists(key):
                self.cache.delete(key)
                print(f"🗑️ Deleted {key}")

def main():
    """Main function demonstrating Redis caching."""
    print("🚀 Redis Caching Example (Python)")
    print("=" * 50)
    
    try:
        # Initialize cache demo
        demo = CacheDemo()
        
        # Show Redis info
        info = demo.cache.get_info()
        print("\n📊 Redis Server Info:")
        for key, value in info.items():
            print(f"  {key}: {value}")
        
        # Test expensive operation with caching
        print("\n💰 Expensive Operation Caching")
        print("-" * 40)
        
        # First call - will be slow
        result1 = demo.expensive_operation(10)
        print(f"Result: {result1}")
        
        # Second call - will be fast (cached)
        result2 = demo.expensive_operation(10)
        print(f"Result: {result2}")
        
        # User session example
        session_key = demo.user_session_example()
        
        # Counter example
        counter_key = demo.counter_example()
        
        # Rate limiting example
        rate_key = demo.rate_limiting_example()
        
        # Interactive mode
        print("\n" + "=" * 50)
        print("🎯 Interactive Cache Demo")
        print("Commands:")
        print("  'set <key> <value>' - Set a cache value")
        print("  'get <key>' - Get a cache value")
        print("  'del <key>' - Delete a cache key")
        print("  'exists <key>' - Check if key exists")
        print("  'ttl <key>' - Get TTL for key")
        print("  'info' - Show Redis info")
        print("  'cleanup' - Clean up demo data")
        print("  'quit' - Exit")
        print("-" * 50)
        
        while True:
            user_input = input("\n🔧 Redis> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'info':
                info = demo.cache.get_info()
                print("📊 Redis Info:")
                for key, value in info.items():
                    print(f"  {key}: {value}")
            elif user_input.lower() == 'cleanup':
                demo.cleanup_example_data()
            elif user_input.startswith('set '):
                parts = user_input.split(' ', 2)
                if len(parts) >= 3:
                    key, value = parts[1], parts[2]
                    success = demo.cache.set(key, value)
                    print(f"✅ Set {key}: {success}")
                else:
                    print("Usage: set <key> <value>")
            elif user_input.startswith('get '):
                key = user_input.split(' ', 1)[1]
                value = demo.cache.get(key)
                print(f"📄 {key}: {value}")
            elif user_input.startswith('del '):
                key = user_input.split(' ', 1)[1]
                success = demo.cache.delete(key)
                print(f"🗑️ Delete {key}: {success}")
            elif user_input.startswith('exists '):
                key = user_input.split(' ', 1)[1]
                exists = demo.cache.exists(key)
                print(f"❓ {key} exists: {exists}")
            elif user_input.startswith('ttl '):
                key = user_input.split(' ', 1)[1]
                ttl = demo.cache.ttl(key)
                print(f"⏰ {key} TTL: {ttl} seconds")
            elif user_input:
                print("Unknown command. Type 'quit' to exit.")
        
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()