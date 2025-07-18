/**
 * Redis Pub/Sub Examples
 * 
 * This example demonstrates:
 * - Real-time messaging with Redis pub/sub
 * - Channel subscriptions and pattern matching
 * - Message broadcasting
 * - Event-driven architecture
 * - WebSocket integration patterns
 * 
 * Usage:
 * npm install redis
 * node example-pub-sub.js
 */

const redis = require('redis');
const { EventEmitter } = require('events');

// Create separate Redis clients for pub/sub
const publisherClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
});

const subscriberClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
});

// Error handling
publisherClient.on('error', (err) => console.error('Publisher Error:', err));
subscriberClient.on('error', (err) => console.error('Subscriber Error:', err));

// ==========================================
// MESSAGE PUBLISHER
// ==========================================

class MessagePublisher {
    constructor(redisClient) {
        this.client = redisClient;
    }

    /**
     * Publish message to a channel
     */
    async publish(channel, message) {
        const messageData = {
            id: Date.now().toString(),
            timestamp: new Date().toISOString(),
            channel,
            payload: message
        };

        const serialized = JSON.stringify(messageData);
        const subscriberCount = await this.client.publish(channel, serialized);
        
        console.log(`📤 Published to '${channel}': ${JSON.stringify(message)} (${subscriberCount} subscribers)`);
        return subscriberCount;
    }

    /**
     * Broadcast message to multiple channels
     */
    async broadcast(channels, message) {
        const promises = channels.map(channel => this.publish(channel, message));
        const results = await Promise.all(promises);
        
        const totalSubscribers = results.reduce((sum, count) => sum + count, 0);
        console.log(`📡 Broadcasted to ${channels.length} channels, reached ${totalSubscribers} subscribers`);
        
        return totalSubscribers;
    }

    /**
     * Publish user-specific message
     */
    async publishToUser(userId, message) {
        const channel = `user:${userId}`;
        return await this.publish(channel, message);
    }

    /**
     * Publish room-specific message
     */
    async publishToRoom(roomId, message) {
        const channel = `room:${roomId}`;
        return await this.publish(channel, message);
    }

    /**
     * Publish system-wide notification
     */
    async publishSystemMessage(message) {
        const channel = 'system:notifications';
        return await this.publish(channel, message);
    }
}

// ==========================================
// MESSAGE SUBSCRIBER
// ==========================================

class MessageSubscriber extends EventEmitter {
    constructor(redisClient) {
        super();
        this.client = redisClient;
        this.subscriptions = new Set();
        this.patternSubscriptions = new Set();
        
        // Handle incoming messages
        this.client.on('message', (channel, message) => {
            this.handleMessage(channel, message);
        });
        
        // Handle pattern messages
        this.client.on('pmessage', (pattern, channel, message) => {
            this.handlePatternMessage(pattern, channel, message);
        });
    }

    /**
     * Subscribe to a channel
     */
    async subscribe(channel) {
        if (!this.subscriptions.has(channel)) {
            await this.client.subscribe(channel);
            this.subscriptions.add(channel);
            console.log(`📥 Subscribed to channel: ${channel}`);
        }
    }

    /**
     * Subscribe to multiple channels
     */
    async subscribeToChannels(channels) {
        const newChannels = channels.filter(channel => !this.subscriptions.has(channel));
        
        if (newChannels.length > 0) {
            await this.client.subscribe(...newChannels);
            newChannels.forEach(channel => this.subscriptions.add(channel));
            console.log(`📥 Subscribed to ${newChannels.length} channels:`, newChannels);
        }
    }

    /**
     * Subscribe to pattern
     */
    async subscribeToPattern(pattern) {
        if (!this.patternSubscriptions.has(pattern)) {
            await this.client.psubscribe(pattern);
            this.patternSubscriptions.add(pattern);
            console.log(`🔍 Subscribed to pattern: ${pattern}`);
        }
    }

    /**
     * Unsubscribe from channel
     */
    async unsubscribe(channel) {
        if (this.subscriptions.has(channel)) {
            await this.client.unsubscribe(channel);
            this.subscriptions.delete(channel);
            console.log(`❌ Unsubscribed from channel: ${channel}`);
        }
    }

    /**
     * Unsubscribe from pattern
     */
    async unsubscribeFromPattern(pattern) {
        if (this.patternSubscriptions.has(pattern)) {
            await this.client.punsubscribe(pattern);
            this.patternSubscriptions.delete(pattern);
            console.log(`❌ Unsubscribed from pattern: ${pattern}`);
        }
    }

    /**
     * Handle incoming message
     */
    handleMessage(channel, message) {
        try {
            const parsedMessage = JSON.parse(message);
            console.log(`📨 Received on '${channel}':`, parsedMessage.payload);
            
            // Emit events for different channel types
            this.emit('message', channel, parsedMessage);
            this.emit(`channel:${channel}`, parsedMessage);
            
            // Emit specific events based on channel naming
            if (channel.startsWith('user:')) {
                const userId = channel.split(':')[1];
                this.emit('userMessage', userId, parsedMessage);
            } else if (channel.startsWith('room:')) {
                const roomId = channel.split(':')[1];
                this.emit('roomMessage', roomId, parsedMessage);
            } else if (channel.startsWith('system:')) {
                this.emit('systemMessage', parsedMessage);
            }
            
        } catch (error) {
            console.error('Error parsing message:', error);
        }
    }

    /**
     * Handle pattern message
     */
    handlePatternMessage(pattern, channel, message) {
        try {
            const parsedMessage = JSON.parse(message);
            console.log(`🔍 Pattern '${pattern}' matched '${channel}':`, parsedMessage.payload);
            
            this.emit('patternMessage', pattern, channel, parsedMessage);
            this.emit(`pattern:${pattern}`, channel, parsedMessage);
            
        } catch (error) {
            console.error('Error parsing pattern message:', error);
        }
    }

    /**
     * Get active subscriptions
     */
    getSubscriptions() {
        return {
            channels: Array.from(this.subscriptions),
            patterns: Array.from(this.patternSubscriptions)
        };
    }
}

// ==========================================
// REAL-TIME CHAT SYSTEM
// ==========================================

class ChatSystem {
    constructor(publisher, subscriber) {
        this.publisher = publisher;
        this.subscriber = subscriber;
        this.rooms = new Map();
        this.users = new Map();
        
        this.setupEventHandlers();
    }

    setupEventHandlers() {
        // Handle room messages
        this.subscriber.on('roomMessage', (roomId, message) => {
            this.handleRoomMessage(roomId, message);
        });

        // Handle user messages
        this.subscriber.on('userMessage', (userId, message) => {
            this.handleUserMessage(userId, message);
        });

        // Handle system messages
        this.subscriber.on('systemMessage', (message) => {
            this.handleSystemMessage(message);
        });
    }

    /**
     * User joins a room
     */
    async joinRoom(userId, roomId, userData = {}) {
        const roomChannel = `room:${roomId}`;
        
        // Subscribe to room
        await this.subscriber.subscribe(roomChannel);
        
        // Track user in room
        if (!this.rooms.has(roomId)) {
            this.rooms.set(roomId, new Set());
        }
        this.rooms.get(roomId).add(userId);
        
        // Track user data
        this.users.set(userId, { ...userData, currentRoom: roomId });
        
        // Notify room about new user
        await this.publisher.publishToRoom(roomId, {
            type: 'user_joined',
            userId,
            userData,
            timestamp: new Date().toISOString()
        });
        
        console.log(`👤 User ${userId} joined room ${roomId}`);
    }

    /**
     * User leaves a room
     */
    async leaveRoom(userId, roomId) {
        const roomChannel = `room:${roomId}`;
        
        // Remove user from room tracking
        if (this.rooms.has(roomId)) {
            this.rooms.get(roomId).delete(userId);
            
            // Remove empty rooms
            if (this.rooms.get(roomId).size === 0) {
                this.rooms.delete(roomId);
                await this.subscriber.unsubscribe(roomChannel);
            }
        }
        
        // Update user data
        const userData = this.users.get(userId);
        if (userData) {
            delete userData.currentRoom;
        }
        
        // Notify room about user leaving
        await this.publisher.publishToRoom(roomId, {
            type: 'user_left',
            userId,
            timestamp: new Date().toISOString()
        });
        
        console.log(`👤 User ${userId} left room ${roomId}`);
    }

    /**
     * Send message to room
     */
    async sendMessageToRoom(userId, roomId, message) {
        const userData = this.users.get(userId);
        
        await this.publisher.publishToRoom(roomId, {
            type: 'chat_message',
            userId,
            username: userData?.username || `User${userId}`,
            message,
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Send private message to user
     */
    async sendPrivateMessage(fromUserId, toUserId, message) {
        const fromUser = this.users.get(fromUserId);
        
        await this.publisher.publishToUser(toUserId, {
            type: 'private_message',
            fromUserId,
            fromUsername: fromUser?.username || `User${fromUserId}`,
            message,
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Handle room message
     */
    handleRoomMessage(roomId, message) {
        const { type, userId, username, message: content } = message.payload;
        
        switch (type) {
            case 'user_joined':
                console.log(`🟢 ${username || userId} joined room ${roomId}`);
                break;
            case 'user_left':
                console.log(`🔴 ${username || userId} left room ${roomId}`);
                break;
            case 'chat_message':
                console.log(`💬 [${roomId}] ${username}: ${content}`);
                break;
        }
    }

    /**
     * Handle user message
     */
    handleUserMessage(userId, message) {
        const { type, fromUsername, message: content } = message.payload;
        
        if (type === 'private_message') {
            console.log(`📩 Private message to ${userId} from ${fromUsername}: ${content}`);
        }
    }

    /**
     * Handle system message
     */
    handleSystemMessage(message) {
        console.log(`🔔 System: ${message.payload.message}`);
    }

    /**
     * Get room statistics
     */
    getRoomStats() {
        const stats = {};
        for (const [roomId, users] of this.rooms) {
            stats[roomId] = {
                userCount: users.size,
                users: Array.from(users)
            };
        }
        return stats;
    }
}

// ==========================================
// NOTIFICATION SYSTEM
// ==========================================

class NotificationSystem {
    constructor(publisher, subscriber) {
        this.publisher = publisher;
        this.subscriber = subscriber;
        this.userSubscriptions = new Map();
        
        this.setupSubscriptions();
    }

    async setupSubscriptions() {
        // Subscribe to all notification patterns
        await this.subscriber.subscribeToPattern('notification:*');
        await this.subscriber.subscribeToPattern('user:*:notification');
        
        this.subscriber.on('patternMessage', (pattern, channel, message) => {
            this.handleNotification(pattern, channel, message);
        });
    }

    /**
     * Subscribe user to notifications
     */
    async subscribeUser(userId, notificationTypes = ['all']) {
        const userChannel = `user:${userId}:notification`;
        await this.subscriber.subscribe(userChannel);
        
        this.userSubscriptions.set(userId, notificationTypes);
        console.log(`🔔 User ${userId} subscribed to notifications:`, notificationTypes);
    }

    /**
     * Send notification to user
     */
    async sendUserNotification(userId, notification) {
        const channel = `user:${userId}:notification`;
        await this.publisher.publish(channel, {
            type: 'user_notification',
            userId,
            notification,
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Send notification to all users
     */
    async sendGlobalNotification(notification) {
        const channel = 'notification:global';
        await this.publisher.publish(channel, {
            type: 'global_notification',
            notification,
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Send notification by type
     */
    async sendNotificationByType(type, notification) {
        const channel = `notification:${type}`;
        await this.publisher.publish(channel, {
            type: 'typed_notification',
            notificationType: type,
            notification,
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Handle notification
     */
    handleNotification(pattern, channel, message) {
        const { type, notification } = message.payload;
        
        switch (type) {
            case 'user_notification':
                console.log(`🔔 User notification: ${notification.title}`);
                break;
            case 'global_notification':
                console.log(`📢 Global notification: ${notification.title}`);
                break;
            case 'typed_notification':
                console.log(`🏷️ ${message.payload.notificationType} notification: ${notification.title}`);
                break;
        }
    }
}

// ==========================================
// REAL-TIME ANALYTICS
// ==========================================

class AnalyticsSystem {
    constructor(publisher, subscriber) {
        this.publisher = publisher;
        this.subscriber = subscriber;
        this.metrics = new Map();
        
        this.setupAnalytics();
    }

    async setupAnalytics() {
        // Subscribe to analytics events
        await this.subscriber.subscribeToPattern('analytics:*');
        
        this.subscriber.on('patternMessage', (pattern, channel, message) => {
            if (pattern === 'analytics:*') {
                this.handleAnalyticsEvent(channel, message);
            }
        });
    }

    /**
     * Track event
     */
    async trackEvent(eventType, data) {
        const channel = `analytics:${eventType}`;
        await this.publisher.publish(channel, {
            eventType,
            data,
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Track user action
     */
    async trackUserAction(userId, action, metadata = {}) {
        await this.trackEvent('user_action', {
            userId,
            action,
            metadata
        });
    }

    /**
     * Track page view
     */
    async trackPageView(userId, page, metadata = {}) {
        await this.trackEvent('page_view', {
            userId,
            page,
            metadata
        });
    }

    /**
     * Handle analytics event
     */
    handleAnalyticsEvent(channel, message) {
        const { eventType, data } = message.payload;
        
        // Update metrics
        if (!this.metrics.has(eventType)) {
            this.metrics.set(eventType, { count: 0, lastSeen: null });
        }
        
        const metric = this.metrics.get(eventType);
        metric.count++;
        metric.lastSeen = new Date().toISOString();
        
        console.log(`📊 Analytics: ${eventType} (${metric.count} times)`);
    }

    /**
     * Get analytics summary
     */
    getAnalyticsSummary() {
        const summary = {};
        for (const [eventType, metric] of this.metrics) {
            summary[eventType] = metric;
        }
        return summary;
    }
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runPubSubExamples() {
    try {
        // Initialize components
        const publisher = new MessagePublisher(publisherClient);
        const subscriber = new MessageSubscriber(subscriberClient);
        
        console.log('=== Basic Pub/Sub Example ===');
        
        // Subscribe to channels
        await subscriber.subscribe('news');
        await subscriber.subscribe('alerts');
        
        // Set up message handlers
        subscriber.on('channel:news', (message) => {
            console.log('📰 News received:', message.payload);
        });
        
        subscriber.on('channel:alerts', (message) => {
            console.log('🚨 Alert received:', message.payload);
        });
        
        // Publish messages
        await publisher.publish('news', { title: 'Breaking News', content: 'Something important happened' });
        await publisher.publish('alerts', { type: 'warning', message: 'System maintenance scheduled' });
        
        // Wait for messages to be processed
        await new Promise(resolve => setTimeout(resolve, 100));

        console.log('\\n=== Pattern Subscription Example ===');
        
        // Subscribe to patterns
        await subscriber.subscribeToPattern('user:*');
        await subscriber.subscribeToPattern('room:*');
        
        // Publish to matching channels
        await publisher.publish('user:123', { type: 'profile_update', data: { name: 'John' } });
        await publisher.publish('room:general', { type: 'message', text: 'Hello everyone!' });
        
        await new Promise(resolve => setTimeout(resolve, 100));

        console.log('\\n=== Chat System Example ===');
        
        // Create chat system
        const chatSystem = new ChatSystem(publisher, subscriber);
        
        // Users join rooms
        await chatSystem.joinRoom('user1', 'general', { username: 'Alice' });
        await chatSystem.joinRoom('user2', 'general', { username: 'Bob' });
        
        // Send messages
        await chatSystem.sendMessageToRoom('user1', 'general', 'Hello everyone!');
        await chatSystem.sendMessageToRoom('user2', 'general', 'Hi Alice!');
        
        // Send private message
        await chatSystem.sendPrivateMessage('user1', 'user2', 'Hey Bob, how are you?');
        
        await new Promise(resolve => setTimeout(resolve, 100));

        console.log('\\n=== Notification System Example ===');
        
        // Create notification system
        const notificationSystem = new NotificationSystem(publisher, subscriber);
        
        // Subscribe user to notifications
        await notificationSystem.subscribeUser('user1', ['security', 'updates']);
        
        // Send notifications
        await notificationSystem.sendUserNotification('user1', {
            title: 'Security Alert',
            body: 'New login detected'
        });
        
        await notificationSystem.sendGlobalNotification({
            title: 'System Update',
            body: 'System will be updated tonight'
        });
        
        await new Promise(resolve => setTimeout(resolve, 100));

        console.log('\\n=== Analytics System Example ===');
        
        // Create analytics system
        const analyticsSystem = new AnalyticsSystem(publisher, subscriber);
        
        // Track events
        await analyticsSystem.trackUserAction('user1', 'login', { ip: '192.168.1.100' });
        await analyticsSystem.trackPageView('user1', '/dashboard', { referrer: '/login' });
        await analyticsSystem.trackEvent('purchase', { userId: 'user1', amount: 99.99 });
        
        await new Promise(resolve => setTimeout(resolve, 100));
        
        console.log('\\n=== Final Statistics ===');
        console.log('Room Stats:', chatSystem.getRoomStats());
        console.log('Analytics Summary:', analyticsSystem.getAnalyticsSummary());
        console.log('Subscriptions:', subscriber.getSubscriptions());
        
    } catch (error) {
        console.error('Error in pub/sub examples:', error);
    }
}

// Run examples when script is executed directly
if (require.main === module) {
    Promise.all([
        new Promise(resolve => publisherClient.on('ready', resolve)),
        new Promise(resolve => subscriberClient.on('ready', resolve))
    ]).then(async () => {
        await runPubSubExamples();
        
        // Close connections
        publisherClient.quit();
        subscriberClient.quit();
    });
}

module.exports = {
    MessagePublisher,
    MessageSubscriber,
    ChatSystem,
    NotificationSystem,
    AnalyticsSystem
};