"""
FastAPI + Redis Caching API Example
Comprehensive caching implementation with Redis for high-performance APIs.

Features:
- Response caching with TTL
- Database query caching
- Cache invalidation strategies
- Cache warming
- Cache statistics
- Distributed caching

Setup:
1. pip install fastapi uvicorn redis aioredis python-dotenv pydantic
2. Start Redis: docker run -p 6379:6379 redis:7-alpine
3. Set REDIS_URL environment variable
4. uvicorn example-caching-api:app --reload

Environment variables:
- REDIS_URL: Redis connection string (default: redis://localhost:6379/0)
- CACHE_TTL: Default cache TTL in seconds (default: 300)
- DEBUG: Enable debug mode (default: True)
"""

from fastapi import FastAPI, HTTPException, Depends, Query, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Union
import redis
import json
import time
import hashlib
import uuid
from datetime import datetime, timedelta
from functools import wraps
from dotenv import load_dotenv
import os
import logging
import asyncio

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))
DEBUG = os.getenv("DEBUG", "True").lower() == "true"

# FastAPI app
app = FastAPI(
    title="FastAPI + Redis Caching API",
    description="High-performance API with Redis caching",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Redis connection
try:
    redis_client = redis.from_url(REDIS_URL, decode_responses=True)
    redis_client.ping()
    logger.info("Connected to Redis successfully")
except Exception as e:
    logger.error(f"Failed to connect to Redis: {e}")
    redis_client = None

# In-memory database simulation
fake_database = {
    "users": {
        "1": {"id": "1", "name": "John Doe", "email": "john@example.com", "age": 30},
        "2": {"id": "2", "name": "Jane Smith", "email": "jane@example.com", "age": 25},
        "3": {"id": "3", "name": "Bob Johnson", "email": "bob@example.com", "age": 35},
    },
    "posts": {
        "1": {"id": "1", "title": "First Post", "content": "This is the first post", "user_id": "1"},
        "2": {"id": "2", "title": "Second Post", "content": "This is the second post", "user_id": "2"},
        "3": {"id": "3", "title": "Third Post", "content": "This is the third post", "user_id": "1"},
    }
}

# Cache statistics
cache_stats = {
    "hits": 0,
    "misses": 0,
    "sets": 0,
    "deletes": 0,
    "errors": 0
}

# Pydantic models
class User(BaseModel):
    id: str
    name: str
    email: str
    age: int

class Post(BaseModel):
    id: str
    title: str
    content: str
    user_id: str

class CacheStats(BaseModel):
    hits: int
    misses: int
    sets: int
    deletes: int
    errors: int
    hit_rate: float
    total_keys: int
    memory_usage: Optional[str] = None

class CacheRequest(BaseModel):
    pattern: Optional[str] = Field(None, description="Pattern to match keys (e.g., 'user:*')")
    ttl: Optional[int] = Field(None, description="Time to live in seconds")

class WarmCacheRequest(BaseModel):
    resource_type: str = Field(..., description="Type of resource to warm (users, posts)")
    ids: Optional[List[str]] = Field(None, description="Specific IDs to warm")

# Cache manager class
class CacheManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.default_ttl = CACHE_TTL
        self.prefix = "cache:"
    
    def _get_key(self, key: str) -> str:
        """Generate cache key with prefix"""
        return f"{self.prefix}{key}"
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        if not self.redis:
            return None
        
        try:
            cache_key = self._get_key(key)
            data = self.redis.get(cache_key)
            
            if data:
                cache_stats["hits"] += 1
                logger.debug(f"Cache hit for key: {key}")
                return json.loads(data)
            else:
                cache_stats["misses"] += 1
                logger.debug(f"Cache miss for key: {key}")
                return None
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache get error for key {key}: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set value in cache"""
        if not self.redis:
            return False
        
        try:
            cache_key = self._get_key(key)
            ttl = ttl or self.default_ttl
            
            serialized_value = json.dumps(value, default=str)
            result = self.redis.setex(cache_key, ttl, serialized_value)
            
            if result:
                cache_stats["sets"] += 1
                logger.debug(f"Cache set for key: {key}, TTL: {ttl}")
            
            return result
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache set error for key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete value from cache"""
        if not self.redis:
            return False
        
        try:
            cache_key = self._get_key(key)
            result = self.redis.delete(cache_key)
            
            if result:
                cache_stats["deletes"] += 1
                logger.debug(f"Cache delete for key: {key}")
            
            return bool(result)
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache delete error for key {key}: {e}")
            return False
    
    def delete_pattern(self, pattern: str) -> int:
        """Delete keys matching pattern"""
        if not self.redis:
            return 0
        
        try:
            cache_pattern = self._get_key(pattern)
            keys = self.redis.keys(cache_pattern)
            
            if keys:
                result = self.redis.delete(*keys)
                cache_stats["deletes"] += result
                logger.debug(f"Cache delete pattern {pattern}: {result} keys deleted")
                return result
            
            return 0
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache delete pattern error for {pattern}: {e}")
            return 0
    
    def exists(self, key: str) -> bool:
        """Check if key exists in cache"""
        if not self.redis:
            return False
        
        try:
            cache_key = self._get_key(key)
            return bool(self.redis.exists(cache_key))
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache exists error for key {key}: {e}")
            return False
    
    def get_ttl(self, key: str) -> int:
        """Get TTL for key"""
        if not self.redis:
            return -1
        
        try:
            cache_key = self._get_key(key)
            return self.redis.ttl(cache_key)
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache TTL error for key {key}: {e}")
            return -1
    
    def get_keys(self, pattern: str = "*") -> List[str]:
        """Get all keys matching pattern"""
        if not self.redis:
            return []
        
        try:
            cache_pattern = self._get_key(pattern)
            keys = self.redis.keys(cache_pattern)
            # Remove prefix from keys
            return [key.replace(self.prefix, "") for key in keys]
        except Exception as e:
            cache_stats["errors"] += 1
            logger.error(f"Cache keys error for pattern {pattern}: {e}")
            return []

# Initialize cache manager
cache_manager = CacheManager(redis_client) if redis_client else None

# Cache decorator
def cache_response(ttl: int = CACHE_TTL, key_prefix: str = "response"):
    """Decorator to cache API responses"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            if not cache_manager:
                return await func(*args, **kwargs)
            
            # Generate cache key from function name and arguments
            cache_key = f"{key_prefix}:{func.__name__}:{hashlib.md5(str(kwargs).encode()).hexdigest()}"
            
            # Try to get from cache
            cached_result = cache_manager.get(cache_key)
            if cached_result is not None:
                return cached_result
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            cache_manager.set(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator

# Database simulation with caching
class DatabaseService:
    def __init__(self, cache_manager: CacheManager):
        self.cache = cache_manager
    
    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user with caching"""
        cache_key = f"user:{user_id}"
        
        # Try cache first
        if self.cache:
            cached_user = self.cache.get(cache_key)
            if cached_user:
                return cached_user
        
        # Simulate database query delay
        time.sleep(0.1)
        
        # Get from "database"
        user = fake_database["users"].get(user_id)
        
        # Cache the result
        if user and self.cache:
            self.cache.set(cache_key, user, ttl=300)
        
        return user
    
    def get_all_users(self) -> List[Dict[str, Any]]:
        """Get all users with caching"""
        cache_key = "users:all"
        
        # Try cache first
        if self.cache:
            cached_users = self.cache.get(cache_key)
            if cached_users:
                return cached_users
        
        # Simulate database query delay
        time.sleep(0.2)
        
        # Get from "database"
        users = list(fake_database["users"].values())
        
        # Cache the result
        if self.cache:
            self.cache.set(cache_key, users, ttl=180)
        
        return users
    
    def get_user_posts(self, user_id: str) -> List[Dict[str, Any]]:
        """Get user posts with caching"""
        cache_key = f"user:{user_id}:posts"
        
        # Try cache first
        if self.cache:
            cached_posts = self.cache.get(cache_key)
            if cached_posts:
                return cached_posts
        
        # Simulate database query delay
        time.sleep(0.15)
        
        # Get from "database"
        posts = [post for post in fake_database["posts"].values() if post["user_id"] == user_id]
        
        # Cache the result
        if self.cache:
            self.cache.set(cache_key, posts, ttl=240)
        
        return posts
    
    def update_user(self, user_id: str, user_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update user and invalidate cache"""
        if user_id not in fake_database["users"]:
            return None
        
        # Update "database"
        fake_database["users"][user_id].update(user_data)
        updated_user = fake_database["users"][user_id]
        
        # Invalidate related cache entries
        if self.cache:
            self.cache.delete(f"user:{user_id}")
            self.cache.delete("users:all")
        
        return updated_user

# Initialize database service
db_service = DatabaseService(cache_manager)

# Dependency
def get_cache_manager() -> CacheManager:
    if not cache_manager:
        raise HTTPException(status_code=503, detail="Redis not available")
    return cache_manager

# Routes
@app.get("/", tags=["root"])
def root():
    """API health check"""
    return {
        "message": "FastAPI + Redis Caching API",
        "version": "1.0.0",
        "redis_connected": redis_client is not None,
        "endpoints": {
            "cache_stats": "/cache/stats",
            "users": "/users/",
            "cache_management": "/cache/"
        }
    }

@app.get("/cache/stats", response_model=CacheStats, tags=["cache"])
def get_cache_stats():
    """Get cache statistics"""
    total_requests = cache_stats["hits"] + cache_stats["misses"]
    hit_rate = cache_stats["hits"] / total_requests if total_requests > 0 else 0
    
    # Get Redis info if available
    memory_usage = None
    total_keys = 0
    
    if redis_client:
        try:
            info = redis_client.info()
            memory_usage = info.get("used_memory_human")
            total_keys = redis_client.dbsize()
        except Exception as e:
            logger.error(f"Error getting Redis info: {e}")
    
    return CacheStats(
        hits=cache_stats["hits"],
        misses=cache_stats["misses"],
        sets=cache_stats["sets"],
        deletes=cache_stats["deletes"],
        errors=cache_stats["errors"],
        hit_rate=hit_rate,
        total_keys=total_keys,
        memory_usage=memory_usage
    )

@app.get("/cache/keys", tags=["cache"])
def get_cache_keys(
    pattern: str = Query("*", description="Pattern to match keys"),
    limit: int = Query(100, description="Maximum number of keys to return")
):
    """Get cache keys matching pattern"""
    if not cache_manager:
        raise HTTPException(status_code=503, detail="Redis not available")
    
    keys = cache_manager.get_keys(pattern)
    
    # Get additional info for each key
    key_info = []
    for key in keys[:limit]:
        ttl = cache_manager.get_ttl(key)
        key_info.append({
            "key": key,
            "ttl": ttl,
            "expires_in": f"{ttl}s" if ttl > 0 else "never" if ttl == -1 else "expired"
        })
    
    return {
        "keys": key_info,
        "total_matched": len(keys),
        "showing": min(len(keys), limit)
    }

@app.post("/cache/clear", tags=["cache"])
def clear_cache(
    cache_request: CacheRequest,
    cache_mgr: CacheManager = Depends(get_cache_manager)
):
    """Clear cache entries"""
    if cache_request.pattern:
        deleted_count = cache_mgr.delete_pattern(cache_request.pattern)
        return {"message": f"Deleted {deleted_count} keys matching pattern: {cache_request.pattern}"}
    else:
        # Clear all cache
        if redis_client:
            redis_client.flushdb()
            return {"message": "All cache cleared"}
        else:
            raise HTTPException(status_code=503, detail="Redis not available")

@app.post("/cache/warm", tags=["cache"])
def warm_cache(
    warm_request: WarmCacheRequest,
    background_tasks: BackgroundTasks
):
    """Warm cache with specified data"""
    def warm_users():
        if warm_request.ids:
            for user_id in warm_request.ids:
                db_service.get_user(user_id)
        else:
            db_service.get_all_users()
    
    def warm_posts():
        if warm_request.ids:
            for user_id in warm_request.ids:
                db_service.get_user_posts(user_id)
    
    if warm_request.resource_type == "users":
        background_tasks.add_task(warm_users)
    elif warm_request.resource_type == "posts":
        background_tasks.add_task(warm_posts)
    else:
        raise HTTPException(status_code=400, detail="Invalid resource type")
    
    return {"message": f"Cache warming started for {warm_request.resource_type}"}

@app.get("/users/", response_model=List[User], tags=["users"])
def get_users():
    """Get all users (cached)"""
    users = db_service.get_all_users()
    return users

@app.get("/users/{user_id}", response_model=User, tags=["users"])
def get_user(user_id: str):
    """Get user by ID (cached)"""
    user = db_service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/users/{user_id}/posts", response_model=List[Post], tags=["users"])
def get_user_posts(user_id: str):
    """Get user posts (cached)"""
    posts = db_service.get_user_posts(user_id)
    return posts

@app.put("/users/{user_id}", response_model=User, tags=["users"])
def update_user(user_id: str, user_data: Dict[str, Any]):
    """Update user (invalidates cache)"""
    updated_user = db_service.update_user(user_id, user_data)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user

@app.get("/expensive-operation", tags=["demo"])
@cache_response(ttl=600, key_prefix="expensive")
async def expensive_operation(
    duration: int = Query(2, description="Simulated operation duration in seconds")
):
    """Simulate expensive operation with caching"""
    # Simulate expensive computation
    await asyncio.sleep(duration)
    
    result = {
        "result": "This was an expensive operation",
        "duration": duration,
        "timestamp": datetime.utcnow().isoformat(),
        "cached": False  # This will be True for cached responses
    }
    
    return result

@app.get("/cache/test", tags=["demo"])
def test_cache_performance():
    """Test cache performance"""
    if not cache_manager:
        raise HTTPException(status_code=503, detail="Redis not available")
    
    # Test cache operations
    start_time = time.time()
    
    # Set operations
    for i in range(100):
        cache_manager.set(f"test:{i}", {"value": i, "timestamp": time.time()})
    
    set_time = time.time() - start_time
    
    # Get operations
    start_time = time.time()
    results = []
    for i in range(100):
        result = cache_manager.get(f"test:{i}")
        if result:
            results.append(result)
    
    get_time = time.time() - start_time
    
    # Cleanup
    cache_manager.delete_pattern("test:*")
    
    return {
        "set_operations": {
            "count": 100,
            "total_time": f"{set_time:.4f}s",
            "avg_time": f"{set_time/100:.6f}s"
        },
        "get_operations": {
            "count": 100,
            "total_time": f"{get_time:.4f}s",
            "avg_time": f"{get_time/100:.6f}s",
            "cache_hits": len(results)
        }
    }

@app.get("/health", tags=["health"])
def health_check():
    """Health check endpoint"""
    try:
        redis_status = "connected"
        if redis_client:
            redis_client.ping()
        else:
            redis_status = "not configured"
        
        return {
            "status": "healthy",
            "redis": redis_status,
            "cache_stats": {
                "hits": cache_stats["hits"],
                "misses": cache_stats["misses"],
                "errors": cache_stats["errors"]
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "redis": "disconnected",
            "error": str(e)
        }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return {"error": exc.detail, "status_code": exc.status_code}

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unexpected error: {exc}")
    return {"error": "Internal server error", "status_code": 500}

# Middleware for request logging
@app.middleware("http")
async def log_requests(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.method} {request.url.path} - "
        f"Status: {response.status_code} - "
        f"Time: {process_time:.3f}s"
    )
    
    return response

# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info("FastAPI + Redis Caching API starting up...")
    if redis_client:
        logger.info("Redis connection established")
    else:
        logger.warning("Redis not available - caching disabled")

# Run with: uvicorn example-caching-api:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")