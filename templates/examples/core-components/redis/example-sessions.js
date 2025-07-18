/**
 * Redis Session Management Examples
 * 
 * This example demonstrates:
 * - User session storage in Redis
 * - Session expiration and cleanup
 * - Secure session management
 * - Session data persistence
 * - Multi-device session handling
 * 
 * Usage:
 * npm install redis crypto
 * node example-sessions.js
 */

const redis = require('redis');
const crypto = require('crypto');

// Create Redis client
const client = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    db: process.env.REDIS_DB || 0
});

client.on('error', (err) => {
    console.error('Redis Client Error:', err);
});

// ==========================================
// SESSION MANAGER CLASS
// ==========================================

class SessionManager {
    constructor(redisClient) {
        this.client = redisClient;
        this.defaultTTL = 24 * 60 * 60; // 24 hours
        this.sessionPrefix = 'session:';
        this.userSessionsPrefix = 'user_sessions:';
    }

    /**
     * Generate secure session ID
     */
    generateSessionId() {
        return crypto.randomBytes(32).toString('hex');
    }

    /**
     * Create a new session
     */
    async createSession(userId, sessionData = {}, ttl = this.defaultTTL) {
        const sessionId = this.generateSessionId();
        const sessionKey = this.sessionPrefix + sessionId;
        const userSessionsKey = this.userSessionsPrefix + userId;

        const session = {
            id: sessionId,
            userId,
            createdAt: new Date().toISOString(),
            lastActivity: new Date().toISOString(),
            ipAddress: sessionData.ipAddress || null,
            userAgent: sessionData.userAgent || null,
            data: sessionData.data || {},
            isActive: true
        };

        // Use Redis transaction for atomicity
        const multi = this.client.multi();
        
        // Store session data
        multi.hmset(sessionKey, session);
        multi.expire(sessionKey, ttl);
        
        // Add to user's session list
        multi.sadd(userSessionsKey, sessionId);
        multi.expire(userSessionsKey, ttl + 3600); // Sessions list lives longer
        
        await multi.exec();

        console.log(`Session created: ${sessionId} for user: ${userId}`);
        return sessionId;
    }

    /**
     * Get session data
     */
    async getSession(sessionId) {
        const sessionKey = this.sessionPrefix + sessionId;
        
        try {
            const session = await this.client.hgetall(sessionKey);
            
            if (!session || Object.keys(session).length === 0) {
                return null;
            }

            // Parse JSON fields
            session.data = JSON.parse(session.data || '{}');
            session.isActive = session.isActive === 'true';
            
            return session;
        } catch (error) {
            console.error('Error getting session:', error);
            return null;
        }
    }

    /**
     * Update session data
     */
    async updateSession(sessionId, updates) {
        const sessionKey = this.sessionPrefix + sessionId;
        
        // Check if session exists
        const exists = await this.client.exists(sessionKey);
        if (!exists) {
            return false;
        }

        // Update last activity
        updates.lastActivity = new Date().toISOString();
        
        // If updating data, stringify it
        if (updates.data) {
            updates.data = JSON.stringify(updates.data);
        }

        await this.client.hmset(sessionKey, updates);
        console.log(`Session updated: ${sessionId}`);
        return true;
    }

    /**
     * Update session activity (touch)
     */
    async touchSession(sessionId, ttl = this.defaultTTL) {
        const sessionKey = this.sessionPrefix + sessionId;
        
        // Update last activity and reset TTL
        const multi = this.client.multi();
        multi.hset(sessionKey, 'lastActivity', new Date().toISOString());
        multi.expire(sessionKey, ttl);
        
        const results = await multi.exec();
        return results[0][1] > 0; // Returns true if session existed
    }

    /**
     * Destroy session
     */
    async destroySession(sessionId) {
        const sessionKey = this.sessionPrefix + sessionId;
        
        // Get session to find user ID
        const session = await this.getSession(sessionId);
        if (!session) {
            return false;
        }

        const userSessionsKey = this.userSessionsPrefix + session.userId;
        
        // Remove from both places
        const multi = this.client.multi();
        multi.del(sessionKey);
        multi.srem(userSessionsKey, sessionId);
        
        await multi.exec();
        
        console.log(`Session destroyed: ${sessionId}`);
        return true;
    }

    /**
     * Get all sessions for a user
     */
    async getUserSessions(userId) {
        const userSessionsKey = this.userSessionsPrefix + userId;
        const sessionIds = await this.client.smembers(userSessionsKey);
        
        const sessions = [];
        for (const sessionId of sessionIds) {
            const session = await this.getSession(sessionId);
            if (session) {
                sessions.push(session);
            } else {
                // Clean up dead session reference
                await this.client.srem(userSessionsKey, sessionId);
            }
        }
        
        return sessions;
    }

    /**
     * Destroy all sessions for a user
     */
    async destroyUserSessions(userId) {
        const sessions = await this.getUserSessions(userId);
        
        for (const session of sessions) {
            await this.destroySession(session.id);
        }
        
        console.log(`Destroyed ${sessions.length} sessions for user: ${userId}`);
        return sessions.length;
    }

    /**
     * Destroy all sessions except current one
     */
    async destroyOtherSessions(userId, currentSessionId) {
        const sessions = await this.getUserSessions(userId);
        let destroyedCount = 0;
        
        for (const session of sessions) {
            if (session.id !== currentSessionId) {
                await this.destroySession(session.id);
                destroyedCount++;
            }
        }
        
        console.log(`Destroyed ${destroyedCount} other sessions for user: ${userId}`);
        return destroyedCount;
    }

    /**
     * Clean up expired sessions
     */
    async cleanupExpiredSessions() {
        const pattern = this.sessionPrefix + '*';
        const keys = await this.client.keys(pattern);
        let cleanedCount = 0;
        
        for (const key of keys) {
            const ttl = await this.client.ttl(key);
            if (ttl === -1) {
                // Session has no TTL, check if it's valid
                const session = await this.client.hgetall(key);
                if (session && session.lastActivity) {
                    const lastActivity = new Date(session.lastActivity);
                    const now = new Date();
                    const hoursSinceActivity = (now - lastActivity) / (1000 * 60 * 60);
                    
                    if (hoursSinceActivity > 24) {
                        await this.client.del(key);
                        cleanedCount++;
                    }
                }
            }
        }
        
        console.log(`Cleaned up ${cleanedCount} expired sessions`);
        return cleanedCount;
    }

    /**
     * Get session statistics
     */
    async getSessionStats() {
        const pattern = this.sessionPrefix + '*';
        const keys = await this.client.keys(pattern);
        
        const stats = {
            totalSessions: keys.length,
            activeSessions: 0,
            inactiveSessions: 0,
            sessionsByUser: {}
        };
        
        for (const key of keys) {
            const session = await this.client.hgetall(key);
            if (session) {
                if (session.isActive === 'true') {
                    stats.activeSessions++;
                } else {
                    stats.inactiveSessions++;
                }
                
                const userId = session.userId;
                stats.sessionsByUser[userId] = (stats.sessionsByUser[userId] || 0) + 1;
            }
        }
        
        return stats;
    }
}

// ==========================================
// SECURE SESSION MIDDLEWARE
// ==========================================

class SecureSessionManager extends SessionManager {
    constructor(redisClient, secretKey) {
        super(redisClient);
        this.secretKey = secretKey;
    }

    /**
     * Generate signed session cookie
     */
    generateSessionCookie(sessionId) {
        const timestamp = Date.now().toString();
        const data = sessionId + '.' + timestamp;
        const signature = crypto
            .createHmac('sha256', this.secretKey)
            .update(data)
            .digest('hex');
        
        return data + '.' + signature;
    }

    /**
     * Verify signed session cookie
     */
    verifySessionCookie(cookie) {
        const parts = cookie.split('.');
        if (parts.length !== 3) {
            return null;
        }
        
        const [sessionId, timestamp, signature] = parts;
        const data = sessionId + '.' + timestamp;
        const expectedSignature = crypto
            .createHmac('sha256', this.secretKey)
            .update(data)
            .digest('hex');
        
        if (signature !== expectedSignature) {
            return null;
        }
        
        // Check if timestamp is not too old (24 hours)
        const now = Date.now();
        const cookieTime = parseInt(timestamp);
        if (now - cookieTime > 24 * 60 * 60 * 1000) {
            return null;
        }
        
        return sessionId;
    }

    /**
     * Create secure session with IP and user agent validation
     */
    async createSecureSession(userId, ipAddress, userAgent, data = {}) {
        const sessionData = {
            ipAddress,
            userAgent,
            data: {
                ...data,
                securityFingerprint: this.generateSecurityFingerprint(ipAddress, userAgent)
            }
        };
        
        return await this.createSession(userId, sessionData);
    }

    /**
     * Generate security fingerprint
     */
    generateSecurityFingerprint(ipAddress, userAgent) {
        return crypto
            .createHash('sha256')
            .update(ipAddress + userAgent)
            .digest('hex');
    }

    /**
     * Validate session security
     */
    async validateSessionSecurity(sessionId, ipAddress, userAgent) {
        const session = await this.getSession(sessionId);
        if (!session) {
            return false;
        }
        
        // Check IP address (optional - might change for mobile users)
        if (session.ipAddress && session.ipAddress !== ipAddress) {
            console.warn(`IP address mismatch for session: ${sessionId}`);
            // You might want to invalidate the session here
        }
        
        // Check user agent fingerprint
        const currentFingerprint = this.generateSecurityFingerprint(ipAddress, userAgent);
        if (session.data.securityFingerprint !== currentFingerprint) {
            console.warn(`Security fingerprint mismatch for session: ${sessionId}`);
            return false;
        }
        
        return true;
    }
}

// ==========================================
// SESSION STORE FOR EXPRESS.JS
// ==========================================

class RedisSessionStore {
    constructor(redisClient) {
        this.client = redisClient;
        this.prefix = 'sess:';
    }

    /**
     * Get session (Express.js compatible)
     */
    get(sessionId, callback) {
        const key = this.prefix + sessionId;
        this.client.get(key, (err, result) => {
            if (err) {
                return callback(err);
            }
            
            if (!result) {
                return callback(null, null);
            }
            
            try {
                const session = JSON.parse(result);
                callback(null, session);
            } catch (parseErr) {
                callback(parseErr);
            }
        });
    }

    /**
     * Set session (Express.js compatible)
     */
    set(sessionId, session, callback) {
        const key = this.prefix + sessionId;
        const ttl = session.cookie && session.cookie.maxAge 
            ? Math.floor(session.cookie.maxAge / 1000) 
            : 3600;
        
        this.client.setex(key, ttl, JSON.stringify(session), callback);
    }

    /**
     * Destroy session (Express.js compatible)
     */
    destroy(sessionId, callback) {
        const key = this.prefix + sessionId;
        this.client.del(key, callback);
    }
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runSessionExamples() {
    try {
        const sessionManager = new SessionManager(client);
        const secureManager = new SecureSessionManager(client, 'your-secret-key');

        console.log('=== Basic Session Management ===');
        
        // Create session
        const sessionId = await sessionManager.createSession('user123', {
            ipAddress: '192.168.1.100',
            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            data: { 
                preferences: { theme: 'dark', language: 'en' },
                cartItems: [1, 2, 3]
            }
        });
        
        console.log('Created session:', sessionId);
        
        // Get session
        const session = await sessionManager.getSession(sessionId);
        console.log('Retrieved session:', session);
        
        // Update session data
        await sessionManager.updateSession(sessionId, {
            data: JSON.stringify({ 
                preferences: { theme: 'light', language: 'es' },
                cartItems: [1, 2, 3, 4]
            })
        });
        
        console.log('Session updated');
        
        // Touch session (extend TTL)
        await sessionManager.touchSession(sessionId);
        console.log('Session touched');

        console.log('\\n=== Multi-Device Session Management ===');
        
        // Create multiple sessions for same user
        const session2 = await sessionManager.createSession('user123', {
            ipAddress: '10.0.0.50',
            userAgent: 'Mobile Safari',
            data: { device: 'mobile' }
        });
        
        const session3 = await sessionManager.createSession('user123', {
            ipAddress: '172.16.0.10',
            userAgent: 'Chrome Desktop',
            data: { device: 'desktop' }
        });
        
        // Get all user sessions
        const userSessions = await sessionManager.getUserSessions('user123');
        console.log(`User has ${userSessions.length} active sessions`);
        
        // Destroy other sessions except current
        await sessionManager.destroyOtherSessions('user123', sessionId);
        
        console.log('\\n=== Secure Session Management ===');
        
        // Create secure session
        const secureSessionId = await secureManager.createSecureSession(
            'user456',
            '192.168.1.100',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        );
        
        // Generate signed cookie
        const signedCookie = secureManager.generateSessionCookie(secureSessionId);
        console.log('Signed cookie:', signedCookie);
        
        // Verify signed cookie
        const verifiedSessionId = secureManager.verifySessionCookie(signedCookie);
        console.log('Verified session ID:', verifiedSessionId);
        
        // Validate session security
        const isValid = await secureManager.validateSessionSecurity(
            secureSessionId,
            '192.168.1.100',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        );
        console.log('Session security valid:', isValid);

        console.log('\\n=== Session Statistics ===');
        
        const stats = await sessionManager.getSessionStats();
        console.log('Session stats:', stats);
        
        // Cleanup expired sessions
        const cleanedCount = await sessionManager.cleanupExpiredSessions();
        console.log(`Cleaned up ${cleanedCount} expired sessions`);

        console.log('\\n=== Session Cleanup ===');
        
        // Clean up test sessions
        await sessionManager.destroyUserSessions('user123');
        await sessionManager.destroyUserSessions('user456');
        
    } catch (error) {
        console.error('Error in session examples:', error);
    }
}

// ==========================================
// SESSION MONITORING
// ==========================================

class SessionMonitor {
    constructor(sessionManager) {
        this.sessionManager = sessionManager;
    }

    /**
     * Monitor session activity
     */
    async monitorSessions() {
        const stats = await this.sessionManager.getSessionStats();
        
        console.log(`Session Monitor - ${new Date().toISOString()}`);
        console.log(`Total Sessions: ${stats.totalSessions}`);
        console.log(`Active Sessions: ${stats.activeSessions}`);
        console.log(`Inactive Sessions: ${stats.inactiveSessions}`);
        
        // Alert if too many sessions for a user
        for (const [userId, count] of Object.entries(stats.sessionsByUser)) {
            if (count > 5) {
                console.warn(`User ${userId} has ${count} sessions (potential security risk)`);
            }
        }
    }

    /**
     * Schedule regular cleanup
     */
    scheduleCleanup() {
        setInterval(async () => {
            await this.sessionManager.cleanupExpiredSessions();
        }, 60 * 60 * 1000); // Every hour
    }
}

// Run examples when script is executed directly
if (require.main === module) {
    client.on('ready', async () => {
        await runSessionExamples();
        
        // Start monitoring
        const sessionManager = new SessionManager(client);
        const monitor = new SessionMonitor(sessionManager);
        await monitor.monitorSessions();
        
        // Close connection
        client.quit();
    });
}

module.exports = {
    SessionManager,
    SecureSessionManager,
    RedisSessionStore,
    SessionMonitor
};