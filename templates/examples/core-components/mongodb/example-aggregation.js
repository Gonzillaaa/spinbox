/**
 * MongoDB Aggregation Examples
 * 
 * This example demonstrates:
 * - Aggregation pipelines
 * - Complex data transformations
 * - Grouping and sorting
 * - Lookup operations
 * - Performance optimization
 * 
 * Usage:
 * npm install mongodb
 * node example-aggregation.js
 */

const { MongoClient, ObjectId } = require('mongodb');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DATABASE_NAME = 'spinbox_examples';

// ==========================================
// AGGREGATION MANAGER
// ==========================================

class AggregationManager {
    constructor(database) {
        this.db = database;
        this.usersCollection = database.getCollection('users');
        this.ordersCollection = database.getCollection('orders');
        this.productsCollection = database.getCollection('products');
    }

    /**
     * Setup sample data for aggregation examples
     */
    async setupSampleData() {
        try {
            // Clear existing data
            await this.usersCollection.deleteMany({});
            await this.ordersCollection.deleteMany({});
            await this.productsCollection.deleteMany({});

            // Insert sample users
            const users = [
                { _id: new ObjectId(), name: 'John Doe', email: 'john@example.com', age: 30, city: 'New York', country: 'USA' },
                { _id: new ObjectId(), name: 'Jane Smith', email: 'jane@example.com', age: 28, city: 'London', country: 'UK' },
                { _id: new ObjectId(), name: 'Bob Wilson', email: 'bob@example.com', age: 35, city: 'Toronto', country: 'Canada' },
                { _id: new ObjectId(), name: 'Alice Brown', email: 'alice@example.com', age: 25, city: 'Sydney', country: 'Australia' },
                { _id: new ObjectId(), name: 'Charlie Davis', email: 'charlie@example.com', age: 40, city: 'Berlin', country: 'Germany' },
            ];

            const userResult = await this.usersCollection.insertMany(users);
            const userIds = Object.values(userResult.insertedIds);

            // Insert sample products
            const products = [
                { _id: new ObjectId(), name: 'Laptop', category: 'Electronics', price: 999.99, stock: 50 },
                { _id: new ObjectId(), name: 'Mouse', category: 'Electronics', price: 29.99, stock: 100 },
                { _id: new ObjectId(), name: 'Book', category: 'Education', price: 19.99, stock: 200 },
                { _id: new ObjectId(), name: 'T-Shirt', category: 'Clothing', price: 24.99, stock: 75 },
                { _id: new ObjectId(), name: 'Coffee Mug', category: 'Home', price: 12.99, stock: 150 },
            ];

            const productResult = await this.productsCollection.insertMany(products);
            const productIds = Object.values(productResult.insertedIds);

            // Insert sample orders
            const orders = [
                {
                    _id: new ObjectId(),
                    userId: userIds[0],
                    items: [
                        { productId: productIds[0], quantity: 1, price: 999.99 },
                        { productId: productIds[1], quantity: 2, price: 29.99 }
                    ],
                    total: 1059.97,
                    status: 'completed',
                    orderDate: new Date('2024-01-15'),
                    shippingAddress: { city: 'New York', country: 'USA' }
                },
                {
                    _id: new ObjectId(),
                    userId: userIds[1],
                    items: [
                        { productId: productIds[2], quantity: 3, price: 19.99 },
                        { productId: productIds[3], quantity: 1, price: 24.99 }
                    ],
                    total: 84.96,
                    status: 'completed',
                    orderDate: new Date('2024-01-16'),
                    shippingAddress: { city: 'London', country: 'UK' }
                },
                {
                    _id: new ObjectId(),
                    userId: userIds[2],
                    items: [
                        { productId: productIds[4], quantity: 2, price: 12.99 }
                    ],
                    total: 25.98,
                    status: 'pending',
                    orderDate: new Date('2024-01-17'),
                    shippingAddress: { city: 'Toronto', country: 'Canada' }
                },
                {
                    _id: new ObjectId(),
                    userId: userIds[0],
                    items: [
                        { productId: productIds[1], quantity: 1, price: 29.99 },
                        { productId: productIds[3], quantity: 2, price: 24.99 }
                    ],
                    total: 79.97,
                    status: 'completed',
                    orderDate: new Date('2024-01-18'),
                    shippingAddress: { city: 'New York', country: 'USA' }
                },
                {
                    _id: new ObjectId(),
                    userId: userIds[3],
                    items: [
                        { productId: productIds[0], quantity: 1, price: 999.99 }
                    ],
                    total: 999.99,
                    status: 'completed',
                    orderDate: new Date('2024-01-19'),
                    shippingAddress: { city: 'Sydney', country: 'Australia' }
                }
            ];

            await this.ordersCollection.insertMany(orders);
            console.log('✅ Sample data inserted successfully');

        } catch (error) {
            console.error('❌ Error setting up sample data:', error);
            throw error;
        }
    }

    // ==========================================
    // BASIC AGGREGATION OPERATIONS
    // ==========================================

    /**
     * Group users by country and count
     */
    async getUsersByCountry() {
        try {
            const pipeline = [
                {
                    $group: {
                        _id: '$country',
                        count: { $sum: 1 },
                        averageAge: { $avg: '$age' },
                        users: { $push: '$name' }
                    }
                },
                {
                    $sort: { count: -1 }
                }
            ];

            const result = await this.usersCollection.aggregate(pipeline).toArray();
            console.log('👥 Users by country:', result);
            return result;
        } catch (error) {
            console.error('❌ Error in getUsersByCountry:', error);
            throw error;
        }
    }

    /**
     * Get order statistics
     */
    async getOrderStatistics() {
        try {
            const pipeline = [
                {
                    $group: {
                        _id: null,
                        totalOrders: { $sum: 1 },
                        totalRevenue: { $sum: '$total' },
                        averageOrderValue: { $avg: '$total' },
                        maxOrderValue: { $max: '$total' },
                        minOrderValue: { $min: '$total' }
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('📊 Order statistics:', result[0]);
            return result[0];
        } catch (error) {
            console.error('❌ Error in getOrderStatistics:', error);
            throw error;
        }
    }

    // ==========================================
    // COMPLEX AGGREGATION OPERATIONS
    // ==========================================

    /**
     * Get sales by product category
     */
    async getSalesByCategory() {
        try {
            const pipeline = [
                // Unwind the items array
                { $unwind: '$items' },
                
                // Lookup product information
                {
                    $lookup: {
                        from: 'products',
                        localField: 'items.productId',
                        foreignField: '_id',
                        as: 'product'
                    }
                },
                
                // Unwind the product array
                { $unwind: '$product' },
                
                // Group by category
                {
                    $group: {
                        _id: '$product.category',
                        totalSales: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                        totalQuantity: { $sum: '$items.quantity' },
                        orderCount: { $sum: 1 },
                        avgOrderValue: { $avg: { $multiply: ['$items.quantity', '$items.price'] } }
                    }
                },
                
                // Sort by total sales
                { $sort: { totalSales: -1 } },
                
                // Add percentage calculation
                {
                    $group: {
                        _id: null,
                        categories: { $push: '$$ROOT' },
                        totalRevenue: { $sum: '$totalSales' }
                    }
                },
                
                // Calculate percentages
                {
                    $project: {
                        categories: {
                            $map: {
                                input: '$categories',
                                as: 'category',
                                in: {
                                    _id: '$$category._id',
                                    totalSales: '$$category.totalSales',
                                    totalQuantity: '$$category.totalQuantity',
                                    orderCount: '$$category.orderCount',
                                    avgOrderValue: '$$category.avgOrderValue',
                                    percentage: {
                                        $multiply: [
                                            { $divide: ['$$category.totalSales', '$totalRevenue'] },
                                            100
                                        ]
                                    }
                                }
                            }
                        }
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('📈 Sales by category:', result[0]?.categories);
            return result[0]?.categories || [];
        } catch (error) {
            console.error('❌ Error in getSalesByCategory:', error);
            throw error;
        }
    }

    /**
     * Get customer analysis
     */
    async getCustomerAnalysis() {
        try {
            const pipeline = [
                // Group by user to get customer statistics
                {
                    $group: {
                        _id: '$userId',
                        totalOrders: { $sum: 1 },
                        totalSpent: { $sum: '$total' },
                        averageOrderValue: { $avg: '$total' },
                        firstOrder: { $min: '$orderDate' },
                        lastOrder: { $max: '$orderDate' }
                    }
                },
                
                // Lookup user information
                {
                    $lookup: {
                        from: 'users',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                
                // Unwind user array
                { $unwind: '$user' },
                
                // Calculate customer lifetime value and recency
                {
                    $addFields: {
                        customerLifetimeValue: '$totalSpent',
                        daysSinceLastOrder: {
                            $divide: [
                                { $subtract: [new Date(), '$lastOrder'] },
                                1000 * 60 * 60 * 24
                            ]
                        },
                        customerSegment: {
                            $cond: {
                                if: { $gte: ['$totalSpent', 500] },
                                then: 'High Value',
                                else: {
                                    $cond: {
                                        if: { $gte: ['$totalSpent', 100] },
                                        then: 'Medium Value',
                                        else: 'Low Value'
                                    }
                                }
                            }
                        }
                    }
                },
                
                // Sort by total spent
                { $sort: { totalSpent: -1 } },
                
                // Project final result
                {
                    $project: {
                        _id: 0,
                        userId: '$_id',
                        customerName: '$user.name',
                        customerEmail: '$user.email',
                        customerCity: '$user.city',
                        customerCountry: '$user.country',
                        totalOrders: 1,
                        totalSpent: 1,
                        averageOrderValue: 1,
                        customerLifetimeValue: 1,
                        customerSegment: 1,
                        daysSinceLastOrder: { $round: ['$daysSinceLastOrder', 0] },
                        firstOrder: 1,
                        lastOrder: 1
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('👤 Customer analysis:', result);
            return result;
        } catch (error) {
            console.error('❌ Error in getCustomerAnalysis:', error);
            throw error;
        }
    }

    // ==========================================
    // TIME-BASED AGGREGATIONS
    // ==========================================

    /**
     * Get sales by time period
     */
    async getSalesByTimePeriod() {
        try {
            const pipeline = [
                {
                    $group: {
                        _id: {
                            year: { $year: '$orderDate' },
                            month: { $month: '$orderDate' },
                            day: { $dayOfMonth: '$orderDate' }
                        },
                        dailySales: { $sum: '$total' },
                        orderCount: { $sum: 1 },
                        averageOrderValue: { $avg: '$total' }
                    }
                },
                {
                    $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
                },
                {
                    $project: {
                        _id: 0,
                        date: {
                            $dateFromParts: {
                                year: '$_id.year',
                                month: '$_id.month',
                                day: '$_id.day'
                            }
                        },
                        dailySales: { $round: ['$dailySales', 2] },
                        orderCount: 1,
                        averageOrderValue: { $round: ['$averageOrderValue', 2] }
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('📅 Sales by time period:', result);
            return result;
        } catch (error) {
            console.error('❌ Error in getSalesByTimePeriod:', error);
            throw error;
        }
    }

    // ==========================================
    // GEOSPATIAL AGGREGATIONS
    // ==========================================

    /**
     * Get sales by geographic region
     */
    async getSalesByRegion() {
        try {
            const pipeline = [
                {
                    $group: {
                        _id: '$shippingAddress.country',
                        totalSales: { $sum: '$total' },
                        orderCount: { $sum: 1 },
                        averageOrderValue: { $avg: '$total' },
                        cities: { $addToSet: '$shippingAddress.city' }
                    }
                },
                {
                    $sort: { totalSales: -1 }
                },
                {
                    $project: {
                        _id: 0,
                        country: '$_id',
                        totalSales: { $round: ['$totalSales', 2] },
                        orderCount: 1,
                        averageOrderValue: { $round: ['$averageOrderValue', 2] },
                        uniqueCities: { $size: '$cities' },
                        cities: 1
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('🌍 Sales by region:', result);
            return result;
        } catch (error) {
            console.error('❌ Error in getSalesByRegion:', error);
            throw error;
        }
    }

    // ==========================================
    // PRODUCT PERFORMANCE ANALYSIS
    // ==========================================

    /**
     * Get product performance metrics
     */
    async getProductPerformance() {
        try {
            const pipeline = [
                // Unwind items array
                { $unwind: '$items' },
                
                // Group by product
                {
                    $group: {
                        _id: '$items.productId',
                        totalQuantitySold: { $sum: '$items.quantity' },
                        totalRevenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
                        orderCount: { $sum: 1 },
                        averageQuantityPerOrder: { $avg: '$items.quantity' },
                        averagePrice: { $avg: '$items.price' }
                    }
                },
                
                // Lookup product details
                {
                    $lookup: {
                        from: 'products',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'product'
                    }
                },
                
                // Unwind product array
                { $unwind: '$product' },
                
                // Calculate performance metrics
                {
                    $addFields: {
                        revenuePerUnit: { $divide: ['$totalRevenue', '$totalQuantitySold'] },
                        stockTurnover: { $divide: ['$totalQuantitySold', '$product.stock'] },
                        performanceScore: {
                            $add: [
                                { $multiply: ['$totalRevenue', 0.4] },
                                { $multiply: ['$totalQuantitySold', 0.3] },
                                { $multiply: ['$orderCount', 0.3] }
                            ]
                        }
                    }
                },
                
                // Sort by performance score
                { $sort: { performanceScore: -1 } },
                
                // Project final result
                {
                    $project: {
                        _id: 0,
                        productId: '$_id',
                        productName: '$product.name',
                        category: '$product.category',
                        currentStock: '$product.stock',
                        totalQuantitySold: 1,
                        totalRevenue: { $round: ['$totalRevenue', 2] },
                        orderCount: 1,
                        averageQuantityPerOrder: { $round: ['$averageQuantityPerOrder', 2] },
                        averagePrice: { $round: ['$averagePrice', 2] },
                        revenuePerUnit: { $round: ['$revenuePerUnit', 2] },
                        stockTurnover: { $round: ['$stockTurnover', 2] },
                        performanceScore: { $round: ['$performanceScore', 2] }
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('🏆 Product performance:', result);
            return result;
        } catch (error) {
            console.error('❌ Error in getProductPerformance:', error);
            throw error;
        }
    }

    // ==========================================
    // ADVANCED AGGREGATION TECHNIQUES
    // ==========================================

    /**
     * Get order fulfillment analysis with window functions
     */
    async getOrderFulfillmentAnalysis() {
        try {
            const pipeline = [
                {
                    $setWindowFields: {
                        partitionBy: '$status',
                        sortBy: { orderDate: 1 },
                        output: {
                            runningTotal: {
                                $sum: '$total',
                                window: {
                                    documents: ['unbounded preceding', 'current']
                                }
                            },
                            orderRank: {
                                $rank: {}
                            }
                        }
                    }
                },
                {
                    $group: {
                        _id: '$status',
                        totalOrders: { $sum: 1 },
                        totalValue: { $sum: '$total' },
                        averageValue: { $avg: '$total' },
                        maxValue: { $max: '$total' },
                        minValue: { $min: '$total' },
                        finalRunningTotal: { $max: '$runningTotal' }
                    }
                },
                {
                    $sort: { totalValue: -1 }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('📋 Order fulfillment analysis:', result);
            return result;
        } catch (error) {
            console.error('❌ Error in getOrderFulfillmentAnalysis:', error);
            throw error;
        }
    }

    /**
     * Get comprehensive business intelligence report
     */
    async getBusinessIntelligenceReport() {
        try {
            const pipeline = [
                {
                    $facet: {
                        // Revenue metrics
                        revenueMetrics: [
                            {
                                $group: {
                                    _id: null,
                                    totalRevenue: { $sum: '$total' },
                                    averageOrderValue: { $avg: '$total' },
                                    totalOrders: { $sum: 1 }
                                }
                            }
                        ],
                        
                        // Status breakdown
                        statusBreakdown: [
                            {
                                $group: {
                                    _id: '$status',
                                    count: { $sum: 1 },
                                    revenue: { $sum: '$total' }
                                }
                            }
                        ],
                        
                        // Top customers
                        topCustomers: [
                            {
                                $group: {
                                    _id: '$userId',
                                    totalSpent: { $sum: '$total' },
                                    orderCount: { $sum: 1 }
                                }
                            },
                            {
                                $lookup: {
                                    from: 'users',
                                    localField: '_id',
                                    foreignField: '_id',
                                    as: 'user'
                                }
                            },
                            { $unwind: '$user' },
                            { $sort: { totalSpent: -1 } },
                            { $limit: 3 },
                            {
                                $project: {
                                    _id: 0,
                                    customerName: '$user.name',
                                    totalSpent: 1,
                                    orderCount: 1
                                }
                            }
                        ],
                        
                        // Geographic distribution
                        geoDistribution: [
                            {
                                $group: {
                                    _id: '$shippingAddress.country',
                                    orderCount: { $sum: 1 },
                                    revenue: { $sum: '$total' }
                                }
                            },
                            { $sort: { revenue: -1 } }
                        ]
                    }
                }
            ];

            const result = await this.ordersCollection.aggregate(pipeline).toArray();
            console.log('📊 Business Intelligence Report:', result[0]);
            return result[0];
        } catch (error) {
            console.error('❌ Error in getBusinessIntelligenceReport:', error);
            throw error;
        }
    }
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runAggregationExamples() {
    const client = new MongoClient(MONGODB_URI);
    
    try {
        await client.connect();
        const db = client.db(DATABASE_NAME);
        const aggregationManager = new AggregationManager({ getCollection: (name) => db.collection(name) });

        console.log('=== Setting up sample data ===');
        await aggregationManager.setupSampleData();

        console.log('\\n=== Basic Aggregations ===');
        await aggregationManager.getUsersByCountry();
        await aggregationManager.getOrderStatistics();

        console.log('\\n=== Complex Aggregations ===');
        await aggregationManager.getSalesByCategory();
        await aggregationManager.getCustomerAnalysis();

        console.log('\\n=== Time-based Aggregations ===');
        await aggregationManager.getSalesByTimePeriod();

        console.log('\\n=== Geographic Aggregations ===');
        await aggregationManager.getSalesByRegion();

        console.log('\\n=== Product Performance ===');
        await aggregationManager.getProductPerformance();

        console.log('\\n=== Advanced Analysis ===');
        await aggregationManager.getOrderFulfillmentAnalysis();
        await aggregationManager.getBusinessIntelligenceReport();

    } catch (error) {
        console.error('Error in aggregation examples:', error);
    } finally {
        await client.close();
    }
}

// Run examples when script is executed directly
if (require.main === module) {
    runAggregationExamples().catch(console.error);
}

module.exports = {
    AggregationManager
};