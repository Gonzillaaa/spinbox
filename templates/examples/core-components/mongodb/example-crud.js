/**
 * MongoDB CRUD Examples
 * 
 * This example demonstrates:
 * - Basic CRUD operations
 * - Document validation
 * - Query optimization
 * - Bulk operations
 * - Error handling
 * 
 * Usage:
 * npm install mongodb
 * node example-crud.js
 */

const { MongoClient, ObjectId } = require('mongodb');

// MongoDB connection configuration
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DATABASE_NAME = 'spinbox_examples';

// ==========================================
// DATABASE CONNECTION
// ==========================================

class DatabaseManager {
    constructor(uri, dbName) {
        this.uri = uri;
        this.dbName = dbName;
        this.client = null;
        this.db = null;
    }

    async connect() {
        try {
            this.client = new MongoClient(this.uri, {
                useNewUrlParser: true,
                useUnifiedTopology: true,
                maxPoolSize: 10,
                serverSelectionTimeoutMS: 5000,
                socketTimeoutMS: 45000,
            });

            await this.client.connect();
            this.db = this.client.db(this.dbName);
            
            console.log(`✅ Connected to MongoDB: ${this.dbName}`);
            return this.db;
        } catch (error) {
            console.error('❌ MongoDB connection error:', error);
            throw error;
        }
    }

    async disconnect() {
        if (this.client) {
            await this.client.close();
            console.log('🔌 Disconnected from MongoDB');
        }
    }

    getCollection(name) {
        if (!this.db) {
            throw new Error('Database not connected');
        }
        return this.db.collection(name);
    }
}

// ==========================================
// USER MANAGEMENT SYSTEM
// ==========================================

class UserManager {
    constructor(database) {
        this.db = database;
        this.collection = database.getCollection('users');
        this.setupValidation();
    }

    /**
     * Set up document validation
     */
    async setupValidation() {
        try {
            await this.db.db.createCollection('users', {
                validator: {
                    $jsonSchema: {
                        bsonType: 'object',
                        required: ['email', 'username', 'createdAt'],
                        properties: {
                            email: {
                                bsonType: 'string',
                                pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$',
                                description: 'Valid email address is required'
                            },
                            username: {
                                bsonType: 'string',
                                minLength: 3,
                                maxLength: 50,
                                description: 'Username must be 3-50 characters'
                            },
                            age: {
                                bsonType: 'int',
                                minimum: 0,
                                maximum: 150,
                                description: 'Age must be between 0 and 150'
                            },
                            status: {
                                bsonType: 'string',
                                enum: ['active', 'inactive', 'pending', 'banned'],
                                description: 'Status must be one of: active, inactive, pending, banned'
                            },
                            createdAt: {
                                bsonType: 'date',
                                description: 'Creation date is required'
                            }
                        }
                    }
                }
            });
        } catch (error) {
            // Collection might already exist
            if (error.code !== 48) { // NamespaceExists
                console.error('Validation setup error:', error);
            }
        }
    }

    // ==========================================
    // CREATE OPERATIONS
    // ==========================================

    /**
     * Create a new user
     */
    async createUser(userData) {
        try {
            const user = {
                ...userData,
                createdAt: new Date(),
                updatedAt: new Date(),
                status: userData.status || 'active'
            };

            const result = await this.collection.insertOne(user);
            console.log(`✅ User created with ID: ${result.insertedId}`);
            
            return {
                success: true,
                id: result.insertedId,
                user: { ...user, _id: result.insertedId }
            };
        } catch (error) {
            console.error('❌ Error creating user:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Create multiple users
     */
    async createUsers(usersData) {
        try {
            const users = usersData.map(userData => ({
                ...userData,
                createdAt: new Date(),
                updatedAt: new Date(),
                status: userData.status || 'active'
            }));

            const result = await this.collection.insertMany(users);
            console.log(`✅ Created ${result.insertedCount} users`);
            
            return {
                success: true,
                count: result.insertedCount,
                ids: result.insertedIds
            };
        } catch (error) {
            console.error('❌ Error creating users:', error);
            return { success: false, error: error.message };
        }
    }

    // ==========================================
    // READ OPERATIONS
    // ==========================================

    /**
     * Get user by ID
     */
    async getUserById(id) {
        try {
            const objectId = ObjectId.isValid(id) ? new ObjectId(id) : id;
            const user = await this.collection.findOne({ _id: objectId });
            
            if (!user) {
                return { success: false, error: 'User not found' };
            }
            
            return { success: true, user };
        } catch (error) {
            console.error('❌ Error getting user:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get user by email
     */
    async getUserByEmail(email) {
        try {
            const user = await this.collection.findOne({ email });
            
            if (!user) {
                return { success: false, error: 'User not found' };
            }
            
            return { success: true, user };
        } catch (error) {
            console.error('❌ Error getting user by email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get all users with pagination
     */
    async getUsers(options = {}) {
        try {
            const {
                page = 1,
                limit = 10,
                sortBy = 'createdAt',
                sortOrder = -1,
                filter = {},
                projection = {}
            } = options;

            const skip = (page - 1) * limit;
            
            const [users, total] = await Promise.all([
                this.collection
                    .find(filter, { projection })
                    .sort({ [sortBy]: sortOrder })
                    .skip(skip)
                    .limit(limit)
                    .toArray(),
                this.collection.countDocuments(filter)
            ]);

            return {
                success: true,
                users,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit),
                    hasNext: page < Math.ceil(total / limit),
                    hasPrev: page > 1
                }
            };
        } catch (error) {
            console.error('❌ Error getting users:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Search users
     */
    async searchUsers(query, options = {}) {
        try {
            const { limit = 10, sortBy = 'createdAt', sortOrder = -1 } = options;

            const filter = {
                $or: [
                    { username: { $regex: query, $options: 'i' } },
                    { email: { $regex: query, $options: 'i' } },
                    { firstName: { $regex: query, $options: 'i' } },
                    { lastName: { $regex: query, $options: 'i' } }
                ]
            };

            const users = await this.collection
                .find(filter)
                .sort({ [sortBy]: sortOrder })
                .limit(limit)
                .toArray();

            return { success: true, users, count: users.length };
        } catch (error) {
            console.error('❌ Error searching users:', error);
            return { success: false, error: error.message };
        }
    }

    // ==========================================
    // UPDATE OPERATIONS
    // ==========================================

    /**
     * Update user by ID
     */
    async updateUser(id, updates) {
        try {
            const objectId = ObjectId.isValid(id) ? new ObjectId(id) : id;
            
            // Add updatedAt timestamp
            const updateData = {
                ...updates,
                updatedAt: new Date()
            };

            const result = await this.collection.updateOne(
                { _id: objectId },
                { $set: updateData }
            );

            if (result.matchedCount === 0) {
                return { success: false, error: 'User not found' };
            }

            console.log(`✅ User updated: ${id}`);
            return { success: true, modifiedCount: result.modifiedCount };
        } catch (error) {
            console.error('❌ Error updating user:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Update multiple users
     */
    async updateUsers(filter, updates) {
        try {
            const updateData = {
                ...updates,
                updatedAt: new Date()
            };

            const result = await this.collection.updateMany(
                filter,
                { $set: updateData }
            );

            console.log(`✅ Updated ${result.modifiedCount} users`);
            return { success: true, modifiedCount: result.modifiedCount };
        } catch (error) {
            console.error('❌ Error updating users:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Increment user field
     */
    async incrementUserField(id, field, amount = 1) {
        try {
            const objectId = ObjectId.isValid(id) ? new ObjectId(id) : id;
            
            const result = await this.collection.updateOne(
                { _id: objectId },
                { 
                    $inc: { [field]: amount },
                    $set: { updatedAt: new Date() }
                }
            );

            if (result.matchedCount === 0) {
                return { success: false, error: 'User not found' };
            }

            return { success: true, modifiedCount: result.modifiedCount };
        } catch (error) {
            console.error('❌ Error incrementing field:', error);
            return { success: false, error: error.message };
        }
    }

    // ==========================================
    // DELETE OPERATIONS
    // ==========================================

    /**
     * Delete user by ID
     */
    async deleteUser(id) {
        try {
            const objectId = ObjectId.isValid(id) ? new ObjectId(id) : id;
            
            const result = await this.collection.deleteOne({ _id: objectId });

            if (result.deletedCount === 0) {
                return { success: false, error: 'User not found' };
            }

            console.log(`✅ User deleted: ${id}`);
            return { success: true, deletedCount: result.deletedCount };
        } catch (error) {
            console.error('❌ Error deleting user:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Delete multiple users
     */
    async deleteUsers(filter) {
        try {
            const result = await this.collection.deleteMany(filter);
            
            console.log(`✅ Deleted ${result.deletedCount} users`);
            return { success: true, deletedCount: result.deletedCount };
        } catch (error) {
            console.error('❌ Error deleting users:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Soft delete user (mark as inactive)
     */
    async softDeleteUser(id) {
        try {
            const result = await this.updateUser(id, { 
                status: 'inactive',
                deletedAt: new Date()
            });
            
            if (result.success) {
                console.log(`✅ User soft deleted: ${id}`);
            }
            
            return result;
        } catch (error) {
            console.error('❌ Error soft deleting user:', error);
            return { success: false, error: error.message };
        }
    }

    // ==========================================
    // BULK OPERATIONS
    // ==========================================

    /**
     * Bulk operations
     */
    async bulkWrite(operations) {
        try {
            const result = await this.collection.bulkWrite(operations);
            
            console.log(`✅ Bulk operation completed:`, {
                inserted: result.insertedCount,
                modified: result.modifiedCount,
                deleted: result.deletedCount
            });
            
            return { success: true, result };
        } catch (error) {
            console.error('❌ Error in bulk operation:', error);
            return { success: false, error: error.message };
        }
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    /**
     * Get user statistics
     */
    async getUserStats() {
        try {
            const stats = await this.collection.aggregate([
                {
                    $group: {
                        _id: '$status',
                        count: { $sum: 1 }
                    }
                }
            ]).toArray();

            const total = await this.collection.countDocuments();
            
            return {
                success: true,
                stats: {
                    total,
                    byStatus: stats.reduce((acc, item) => {
                        acc[item._id] = item.count;
                        return acc;
                    }, {})
                }
            };
        } catch (error) {
            console.error('❌ Error getting user stats:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get recent users
     */
    async getRecentUsers(limit = 10) {
        try {
            const users = await this.collection
                .find({})
                .sort({ createdAt: -1 })
                .limit(limit)
                .toArray();

            return { success: true, users };
        } catch (error) {
            console.error('❌ Error getting recent users:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Check if user exists
     */
    async userExists(email) {
        try {
            const count = await this.collection.countDocuments({ email });
            return count > 0;
        } catch (error) {
            console.error('❌ Error checking user existence:', error);
            return false;
        }
    }
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runCRUDExamples() {
    const dbManager = new DatabaseManager(MONGODB_URI, DATABASE_NAME);
    
    try {
        // Connect to database
        await dbManager.connect();
        const userManager = new UserManager(dbManager);

        console.log('=== CREATE OPERATIONS ===');
        
        // Create single user
        const createResult = await userManager.createUser({
            email: 'john.doe@example.com',
            username: 'johndoe',
            firstName: 'John',
            lastName: 'Doe',
            age: 30
        });
        
        const userId = createResult.id;
        console.log('Created user:', createResult);

        // Create multiple users
        const bulkCreateResult = await userManager.createUsers([
            {
                email: 'jane.smith@example.com',
                username: 'janesmith',
                firstName: 'Jane',
                lastName: 'Smith',
                age: 28
            },
            {
                email: 'bob.wilson@example.com',
                username: 'bobwilson',
                firstName: 'Bob',
                lastName: 'Wilson',
                age: 35
            }
        ]);
        
        console.log('Bulk create result:', bulkCreateResult);

        console.log('\\n=== READ OPERATIONS ===');
        
        // Get user by ID
        const getUserResult = await userManager.getUserById(userId);
        console.log('Get user by ID:', getUserResult);

        // Get user by email
        const getUserByEmailResult = await userManager.getUserByEmail('jane.smith@example.com');
        console.log('Get user by email:', getUserByEmailResult);

        // Get all users with pagination
        const getUsersResult = await userManager.getUsers({
            page: 1,
            limit: 5,
            sortBy: 'createdAt',
            sortOrder: -1
        });
        console.log('Get users:', getUsersResult);

        // Search users
        const searchResult = await userManager.searchUsers('john');
        console.log('Search users:', searchResult);

        console.log('\\n=== UPDATE OPERATIONS ===');
        
        // Update user
        const updateResult = await userManager.updateUser(userId, {
            firstName: 'John Updated',
            age: 31
        });
        console.log('Update user:', updateResult);

        // Update multiple users
        const bulkUpdateResult = await userManager.updateUsers(
            { status: 'active' },
            { lastActive: new Date() }
        );
        console.log('Bulk update result:', bulkUpdateResult);

        // Increment field
        const incrementResult = await userManager.incrementUserField(userId, 'loginCount', 1);
        console.log('Increment result:', incrementResult);

        console.log('\\n=== BULK OPERATIONS ===');
        
        // Bulk operations
        const bulkOps = [
            {
                updateOne: {
                    filter: { email: 'john.doe@example.com' },
                    update: { $set: { status: 'premium' } }
                }
            },
            {
                updateMany: {
                    filter: { age: { $gte: 30 } },
                    update: { $set: { category: 'senior' } }
                }
            }
        ];
        
        const bulkResult = await userManager.bulkWrite(bulkOps);
        console.log('Bulk write result:', bulkResult);

        console.log('\\n=== UTILITY OPERATIONS ===');
        
        // Get user statistics
        const statsResult = await userManager.getUserStats();
        console.log('User stats:', statsResult);

        // Get recent users
        const recentUsers = await userManager.getRecentUsers(3);
        console.log('Recent users:', recentUsers);

        // Check if user exists
        const userExists = await userManager.userExists('john.doe@example.com');
        console.log('User exists:', userExists);

        console.log('\\n=== DELETE OPERATIONS ===');
        
        // Soft delete
        const softDeleteResult = await userManager.softDeleteUser(userId);
        console.log('Soft delete result:', softDeleteResult);

        // Delete users by filter
        const deleteResult = await userManager.deleteUsers({
            status: 'inactive'
        });
        console.log('Delete result:', deleteResult);

        // Clean up remaining test data
        await userManager.deleteUsers({});
        console.log('Cleaned up test data');

    } catch (error) {
        console.error('Error in CRUD examples:', error);
    } finally {
        await dbManager.disconnect();
    }
}

// Run examples when script is executed directly
if (require.main === module) {
    runCRUDExamples().catch(console.error);
}

module.exports = {
    DatabaseManager,
    UserManager
};