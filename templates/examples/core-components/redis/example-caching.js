/**
 * Redis Caching Examples
 * 
 * This example demonstrates:
 * - Basic caching patterns
 * - Cache invalidation strategies
 * - TTL (Time To Live) management
 * - Cache-aside pattern
 * - Write-through caching
 * - Performance optimization
 * 
 * Usage:
 * npm install redis
 * node example-caching.js
 */

const redis = require('redis');

// Create Redis client with connection pooling
const client = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    db: process.env.REDIS_DB || 0,
    retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            return new Error('Redis server refused connection');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Retry time exhausted');
        }
        if (options.attempt > 10) {
            return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
    }
});

// Error handling
client.on('error', (err) => {
    console.error('Redis Client Error:', err);
});

client.on('connect', () => {
    console.log('Connected to Redis');
});

// ==========================================
// BASIC CACHING PATTERNS
// ==========================================

class CacheManager {
    constructor(redisClient) {
        this.client = redisClient;
        this.defaultTTL = 3600; // 1 hour
    }

    /**
     * Cache-aside pattern: Check cache first, then database
     */
    async get(key) {
        try {
            const cachedValue = await this.client.get(key);
            if (cachedValue) {
                console.log(`Cache HIT for key: ${key}`);
                return JSON.parse(cachedValue);
            }
            console.log(`Cache MISS for key: ${key}`);
            return null;
        } catch (error) {
            console.error('Cache get error:', error);
            return null;
        }
    }

    /**
     * Set value in cache with TTL
     */
    async set(key, value, ttl = this.defaultTTL) {
        try {
            const serialized = JSON.stringify(value);
            await this.client.setex(key, ttl, serialized);
            console.log(`Cache SET for key: ${key}, TTL: ${ttl}s`);
            return true;
        } catch (error) {
            console.error('Cache set error:', error);
            return false;
        }
    }

    /**
     * Delete from cache
     */
    async delete(key) {
        try {
            const result = await this.client.del(key);
            console.log(`Cache DELETE for key: ${key}`);
            return result > 0;
        } catch (error) {
            console.error('Cache delete error:', error);
            return false;
        }
    }

    /**
     * Check if key exists in cache
     */
    async exists(key) {
        try {
            const result = await this.client.exists(key);
            return result === 1;
        } catch (error) {
            console.error('Cache exists error:', error);
            return false;
        }
    }

    /**
     * Get TTL for a key
     */
    async getTTL(key) {
        try {
            const ttl = await this.client.ttl(key);
            return ttl;
        } catch (error) {
            console.error('Cache TTL error:', error);
            return -1;
        }
    }

    /**
     * Set TTL for existing key
     */
    async setTTL(key, ttl) {
        try {
            const result = await this.client.expire(key, ttl);
            return result === 1;
        } catch (error) {
            console.error('Cache set TTL error:', error);
            return false;
        }
    }
}

// ==========================================
// DATABASE SIMULATION
// ==========================================

class MockDatabase {
    constructor() {
        this.users = new Map([
            ['user:1', { id: 1, name: 'John Doe', email: 'john@example.com', role: 'admin' }],
            ['user:2', { id: 2, name: 'Jane Smith', email: 'jane@example.com', role: 'user' }],
            ['user:3', { id: 3, name: 'Bob Johnson', email: 'bob@example.com', role: 'user' }],
        ]);
        
        this.products = new Map([
            ['product:1', { id: 1, name: 'Laptop', price: 999.99, category: 'Electronics' }],
            ['product:2', { id: 2, name: 'Mouse', price: 29.99, category: 'Electronics' }],
            ['product:3', { id: 3, name: 'Book', price: 19.99, category: 'Education' }],
        ]);
    }

    async getUser(id) {
        // Simulate database delay
        await new Promise(resolve => setTimeout(resolve, 100));
        const user = this.users.get(`user:${id}`);
        console.log(`Database query for user:${id}`);
        return user || null;
    }

    async getProduct(id) {
        // Simulate database delay
        await new Promise(resolve => setTimeout(resolve, 100));
        const product = this.products.get(`product:${id}`);
        console.log(`Database query for product:${id}`);
        return product || null;
    }

    async updateUser(id, userData) {
        // Simulate database delay
        await new Promise(resolve => setTimeout(resolve, 150));
        const key = `user:${id}`;
        if (this.users.has(key)) {
            this.users.set(key, { ...this.users.get(key), ...userData });
            console.log(`Database update for user:${id}`);
            return true;
        }
        return false;
    }
}

// ==========================================
// SERVICE LAYER WITH CACHING
// ==========================================

class UserService {
    constructor(cache, database) {
        this.cache = cache;
        this.db = database;
    }

    /**
     * Get user with cache-aside pattern
     */
    async getUser(id) {
        const cacheKey = `user:${id}`;
        
        // Try cache first
        let user = await this.cache.get(cacheKey);
        if (user) {
            return user;
        }
        
        // Cache miss - get from database
        user = await this.db.getUser(id);
        if (user) {
            // Cache the result
            await this.cache.set(cacheKey, user, 1800); // 30 minutes
        }
        
        return user;
    }

    /**
     * Update user with write-through caching
     */
    async updateUser(id, userData) {
        const cacheKey = `user:${id}`;
        
        // Update database
        const success = await this.db.updateUser(id, userData);
        if (success) {
            // Invalidate cache
            await this.cache.delete(cacheKey);
            
            // Or update cache immediately (write-through)
            const updatedUser = await this.db.getUser(id);
            if (updatedUser) {
                await this.cache.set(cacheKey, updatedUser, 1800);
            }
        }
        
        return success;
    }

    /**
     * Get multiple users with batch caching
     */
    async getUsers(ids) {
        const results = [];
        const missedIds = [];
        
        // Check cache for each user
        for (const id of ids) {
            const cacheKey = `user:${id}`;
            const cachedUser = await this.cache.get(cacheKey);
            
            if (cachedUser) {
                results.push(cachedUser);
            } else {
                missedIds.push(id);
            }
        }
        
        // Fetch missed users from database
        for (const id of missedIds) {
            const user = await this.db.getUser(id);
            if (user) {
                results.push(user);
                // Cache the result
                await this.cache.set(`user:${id}`, user, 1800);
            }
        }
        
        return results;
    }
}

// ==========================================
// ADVANCED CACHING PATTERNS
// ==========================================

class AdvancedCache {
    constructor(redisClient) {
        this.client = redisClient;
    }

    /**
     * Memoization with cache
     */
    memoize(fn, keyGenerator, ttl = 3600) {
        return async (...args) => {
            const cacheKey = keyGenerator(...args);
            
            // Check cache
            const cached = await this.client.get(cacheKey);
            if (cached) {
                console.log(`Memoized cache hit: ${cacheKey}`);
                return JSON.parse(cached);
            }
            
            // Execute function
            const result = await fn(...args);
            
            // Cache result
            await this.client.setex(cacheKey, ttl, JSON.stringify(result));
            console.log(`Memoized cache set: ${cacheKey}`);
            
            return result;
        };
    }

    /**
     * Cache with tags for selective invalidation
     */
    async setWithTags(key, value, tags, ttl = 3600) {
        const multi = this.client.multi();
        
        // Set the main key
        multi.setex(key, ttl, JSON.stringify(value));
        
        // Add to tag sets
        for (const tag of tags) {
            multi.sadd(`tag:${tag}`, key);
            multi.expire(`tag:${tag}`, ttl + 3600); // Tags live longer
        }
        
        await multi.exec();
    }

    /**
     * Invalidate all keys with a specific tag
     */
    async invalidateTag(tag) {
        const keys = await this.client.smembers(`tag:${tag}`);
        if (keys.length > 0) {
            await this.client.del(...keys);
            await this.client.del(`tag:${tag}`);
        }
        console.log(`Invalidated ${keys.length} keys with tag: ${tag}`);
    }

    /**
     * Distributed locking for cache warming
     */
    async withLock(lockKey, fn, timeout = 30) {
        const lockValue = Date.now().toString();
        const acquired = await this.client.set(lockKey, lockValue, 'PX', timeout * 1000, 'NX');
        
        if (!acquired) {
            throw new Error('Could not acquire lock');
        }
        
        try {
            return await fn();
        } finally {
            // Release lock only if we still own it
            const script = `
                if redis.call("get", KEYS[1]) == ARGV[1] then
                    return redis.call("del", KEYS[1])
                else
                    return 0
                end
            `;
            await this.client.eval(script, 1, lockKey, lockValue);
        }
    }
}

// ==========================================
// PERFORMANCE MONITORING
// ==========================================

class CacheMonitor {
    constructor(redisClient) {
        this.client = redisClient;
        this.stats = {
            hits: 0,
            misses: 0,
            sets: 0,
            deletes: 0
        };
    }

    recordHit() {
        this.stats.hits++;
    }

    recordMiss() {
        this.stats.misses++;
    }

    recordSet() {
        this.stats.sets++;
    }

    recordDelete() {
        this.stats.deletes++;
    }

    getStats() {
        const total = this.stats.hits + this.stats.misses;
        const hitRate = total > 0 ? (this.stats.hits / total) * 100 : 0;
        
        return {
            ...this.stats,
            hitRate: hitRate.toFixed(2) + '%',
            total
        };
    }

    async getRedisInfo() {
        const info = await this.client.info();
        return info;
    }

    async getMemoryUsage() {
        const info = await this.client.info('memory');
        return info;
    }
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runCachingExamples() {
    try {
        // Initialize components
        const cache = new CacheManager(client);
        const db = new MockDatabase();
        const userService = new UserService(cache, db);
        const advancedCache = new AdvancedCache(client);
        const monitor = new CacheMonitor(client);

        console.log('=== Basic Caching Example ===');
        
        // First request - cache miss
        console.log('\\n1. First request (cache miss):');
        const user1 = await userService.getUser(1);
        console.log('User:', user1);
        
        // Second request - cache hit
        console.log('\\n2. Second request (cache hit):');
        const user1Again = await userService.getUser(1);
        console.log('User:', user1Again);
        
        // Update user - cache invalidation
        console.log('\\n3. Update user (cache invalidation):');
        await userService.updateUser(1, { name: 'John Updated' });
        
        // Request after update - cache miss
        console.log('\\n4. Request after update (cache miss):');
        const updatedUser = await userService.getUser(1);
        console.log('Updated User:', updatedUser);

        console.log('\\n=== Batch Caching Example ===');
        
        // Batch request
        const users = await userService.getUsers([1, 2, 3]);
        console.log('Batch Users:', users.map(u => u.name));

        console.log('\\n=== Memoization Example ===');
        
        // Expensive calculation
        const expensiveFunction = async (n) => {
            await new Promise(resolve => setTimeout(resolve, 1000));
            return n * n;
        };
        
        const memoized = advancedCache.memoize(
            expensiveFunction,
            (n) => `calc:square:${n}`,
            300 // 5 minutes
        );
        
        console.log('First call (slow):');
        const result1 = await memoized(5);
        console.log('Result:', result1);
        
        console.log('Second call (fast):');
        const result2 = await memoized(5);
        console.log('Result:', result2);

        console.log('\\n=== Cache with Tags Example ===');
        
        // Set cache with tags
        await advancedCache.setWithTags('product:1', { name: 'Laptop', price: 999 }, ['products', 'electronics']);
        await advancedCache.setWithTags('product:2', { name: 'Mouse', price: 29 }, ['products', 'electronics']);
        await advancedCache.setWithTags('user:1', { name: 'John' }, ['users']);
        
        // Invalidate by tag
        await advancedCache.invalidateTag('electronics');

        console.log('\\n=== Cache Statistics ===');
        console.log('Cache Stats:', monitor.getStats());
        
        // Redis memory info
        const memInfo = await monitor.getMemoryUsage();
        console.log('Redis Memory Info:', memInfo.split('\\n').slice(0, 5).join('\\n'));

    } catch (error) {
        console.error('Error in caching examples:', error);
    }
}

// ==========================================
// CACHE WARMING STRATEGIES
// ==========================================

class CacheWarmer {
    constructor(cache, database) {
        this.cache = cache;
        this.db = database;
    }

    /**
     * Warm cache with popular users
     */
    async warmUserCache() {
        const popularUserIds = [1, 2, 3]; // These would come from analytics
        
        console.log('Warming user cache...');
        for (const id of popularUserIds) {
            const user = await this.db.getUser(id);
            if (user) {
                await this.cache.set(`user:${id}`, user, 3600);
                console.log(`Warmed cache for user:${id}`);
            }
        }
    }

    /**
     * Scheduled cache refresh
     */
    async scheduleRefresh() {
        setInterval(async () => {
            console.log('Refreshing cache...');
            await this.warmUserCache();
        }, 30 * 60 * 1000); // Every 30 minutes
    }
}

// Run examples when script is executed directly
if (require.main === module) {
    client.on('ready', async () => {
        await runCachingExamples();
        
        // Warm cache example
        const cache = new CacheManager(client);
        const db = new MockDatabase();
        const warmer = new CacheWarmer(cache, db);
        await warmer.warmUserCache();
        
        // Close connection
        client.quit();
    });
}

module.exports = {
    CacheManager,
    UserService,
    AdvancedCache,
    CacheMonitor,
    CacheWarmer
};