#!/usr/bin/env python3
"""
MongoDB Aggregation Example (Python)

This example demonstrates MongoDB aggregation pipeline operations
for complex data analysis and reporting.
"""

import os
import sys
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.errors import ConnectionFailure, PyMongoError
from bson import ObjectId
import random
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

@dataclass
class Order:
    """Order data model."""
    customer_id: str
    customer_name: str
    customer_email: str
    items: List[Dict[str, Any]]
    total_amount: float
    status: str = "pending"
    created_at: datetime = None
    region: str = "US"
    _id: Optional[ObjectId] = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()

@dataclass
class SalesReport:
    """Sales report data model."""
    period: str
    total_sales: float
    total_orders: int
    average_order_value: float
    top_products: List[Dict[str, Any]]
    customer_segments: List[Dict[str, Any]]

class MongoAggregationDemo:
    """MongoDB aggregation operations demonstration."""
    
    def __init__(self, connection_string: str = None, database_name: str = "sales_analytics"):
        """Initialize the aggregation demo."""
        
        # Get connection string from environment or use default
        self.connection_string = connection_string or os.getenv(
            "MONGODB_URI", 
            "mongodb://localhost:27017/"
        )
        
        self.database_name = database_name
        
        # Initialize client
        try:
            self.client = MongoClient(self.connection_string)
            self.db = self.client[self.database_name]
            
            # Test connection
            self.client.admin.command('ping')
            print(f"✅ Connected to MongoDB: {self.database_name}")
            
        except ConnectionFailure as e:
            print(f"❌ Failed to connect to MongoDB: {e}")
            raise
    
    def seed_orders_data(self, num_orders: int = 100):
        """Seed database with sample orders data."""
        print(f"\n🌱 Seeding {num_orders} sample orders...")
        
        # Sample data
        customers = [
            {"id": "cust001", "name": "Alice Johnson", "email": "alice@example.com", "region": "US"},
            {"id": "cust002", "name": "Bob Smith", "email": "bob@example.com", "region": "EU"},
            {"id": "cust003", "name": "Charlie Brown", "email": "charlie@example.com", "region": "US"},
            {"id": "cust004", "name": "Diana Prince", "email": "diana@example.com", "region": "APAC"},
            {"id": "cust005", "name": "Eve Wilson", "email": "eve@example.com", "region": "EU"},
            {"id": "cust006", "name": "Frank Miller", "email": "frank@example.com", "region": "US"},
            {"id": "cust007", "name": "Grace Lee", "email": "grace@example.com", "region": "APAC"},
            {"id": "cust008", "name": "Henry Davis", "email": "henry@example.com", "region": "EU"}
        ]
        
        products = [
            {"id": "prod001", "name": "Laptop Pro", "price": 1299.99, "category": "Electronics"},
            {"id": "prod002", "name": "Wireless Mouse", "price": 29.99, "category": "Electronics"},
            {"id": "prod003", "name": "Coffee Mug", "price": 15.99, "category": "Kitchen"},
            {"id": "prod004", "name": "Python Book", "price": 39.99, "category": "Books"},
            {"id": "prod005", "name": "Notebook", "price": 8.99, "category": "Office"},
            {"id": "prod006", "name": "Desk Chair", "price": 199.99, "category": "Furniture"},
            {"id": "prod007", "name": "Monitor", "price": 299.99, "category": "Electronics"},
            {"id": "prod008", "name": "Keyboard", "price": 79.99, "category": "Electronics"}
        ]
        
        statuses = ["pending", "processing", "shipped", "delivered", "cancelled"]
        
        orders = []
        for i in range(num_orders):
            customer = random.choice(customers)
            
            # Random number of items (1-5)
            num_items = random.randint(1, 5)
            items = []
            total_amount = 0
            
            for _ in range(num_items):
                product = random.choice(products)
                quantity = random.randint(1, 3)
                item_total = product["price"] * quantity
                
                items.append({
                    "product_id": product["id"],
                    "product_name": product["name"],
                    "category": product["category"],
                    "price": product["price"],
                    "quantity": quantity,
                    "total": item_total
                })
                
                total_amount += item_total
            
            # Random date within last 6 months
            days_ago = random.randint(0, 180)
            created_at = datetime.now() - timedelta(days=days_ago)
            
            order = Order(
                customer_id=customer["id"],
                customer_name=customer["name"],
                customer_email=customer["email"],
                items=items,
                total_amount=round(total_amount, 2),
                status=random.choice(statuses),
                created_at=created_at,
                region=customer["region"]
            )
            
            orders.append(asdict(order))
        
        # Insert orders
        result = self.db.orders.insert_many(orders)
        print(f"✅ Inserted {len(result.inserted_ids)} orders")
        
        # Create indexes
        self.db.orders.create_index([("customer_id", ASCENDING)])
        self.db.orders.create_index([("created_at", DESCENDING)])
        self.db.orders.create_index([("region", ASCENDING)])
        self.db.orders.create_index([("status", ASCENDING)])
        
        print("✅ Indexes created")
    
    def sales_by_month(self) -> List[Dict[str, Any]]:
        """Aggregate sales by month."""
        pipeline = [
            {
                "$group": {
                    "_id": {
                        "year": {"$year": "$created_at"},
                        "month": {"$month": "$created_at"}
                    },
                    "total_sales": {"$sum": "$total_amount"},
                    "total_orders": {"$sum": 1},
                    "average_order": {"$avg": "$total_amount"}
                }
            },
            {
                "$sort": {"_id.year": 1, "_id.month": 1}
            },
            {
                "$project": {
                    "_id": 0,
                    "year": "$_id.year",
                    "month": "$_id.month",
                    "total_sales": {"$round": ["$total_sales", 2]},
                    "total_orders": 1,
                    "average_order": {"$round": ["$average_order", 2]}
                }
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def top_customers(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get top customers by total spending."""
        pipeline = [
            {
                "$group": {
                    "_id": "$customer_id",
                    "customer_name": {"$first": "$customer_name"},
                    "customer_email": {"$first": "$customer_email"},
                    "region": {"$first": "$region"},
                    "total_spent": {"$sum": "$total_amount"},
                    "total_orders": {"$sum": 1},
                    "average_order": {"$avg": "$total_amount"}
                }
            },
            {
                "$sort": {"total_spent": -1}
            },
            {
                "$limit": limit
            },
            {
                "$project": {
                    "_id": 0,
                    "customer_id": "$_id",
                    "customer_name": 1,
                    "customer_email": 1,
                    "region": 1,
                    "total_spent": {"$round": ["$total_spent", 2]},
                    "total_orders": 1,
                    "average_order": {"$round": ["$average_order", 2]}
                }
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def product_performance(self) -> List[Dict[str, Any]]:
        """Analyze product performance."""
        pipeline = [
            {
                "$unwind": "$items"
            },
            {
                "$group": {
                    "_id": "$items.product_id",
                    "product_name": {"$first": "$items.product_name"},
                    "category": {"$first": "$items.category"},
                    "total_quantity": {"$sum": "$items.quantity"},
                    "total_revenue": {"$sum": "$items.total"},
                    "orders_count": {"$sum": 1},
                    "average_price": {"$avg": "$items.price"}
                }
            },
            {
                "$sort": {"total_revenue": -1}
            },
            {
                "$project": {
                    "_id": 0,
                    "product_id": "$_id",
                    "product_name": 1,
                    "category": 1,
                    "total_quantity": 1,
                    "total_revenue": {"$round": ["$total_revenue", 2]},
                    "orders_count": 1,
                    "average_price": {"$round": ["$average_price", 2]}
                }
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def regional_analysis(self) -> List[Dict[str, Any]]:
        """Analyze sales by region."""
        pipeline = [
            {
                "$group": {
                    "_id": "$region",
                    "total_sales": {"$sum": "$total_amount"},
                    "total_orders": {"$sum": 1},
                    "unique_customers": {"$addToSet": "$customer_id"},
                    "average_order": {"$avg": "$total_amount"}
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "region": "$_id",
                    "total_sales": {"$round": ["$total_sales", 2]},
                    "total_orders": 1,
                    "unique_customers": {"$size": "$unique_customers"},
                    "average_order": {"$round": ["$average_order", 2]}
                }
            },
            {
                "$sort": {"total_sales": -1}
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def order_status_breakdown(self) -> List[Dict[str, Any]]:
        """Analyze orders by status."""
        pipeline = [
            {
                "$group": {
                    "_id": "$status",
                    "count": {"$sum": 1},
                    "total_value": {"$sum": "$total_amount"},
                    "average_value": {"$avg": "$total_amount"}
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "status": "$_id",
                    "count": 1,
                    "total_value": {"$round": ["$total_value", 2]},
                    "average_value": {"$round": ["$average_value", 2]}
                }
            },
            {
                "$sort": {"count": -1}
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def customer_segmentation(self) -> List[Dict[str, Any]]:
        """Segment customers by spending behavior."""
        pipeline = [
            {
                "$group": {
                    "_id": "$customer_id",
                    "customer_name": {"$first": "$customer_name"},
                    "total_spent": {"$sum": "$total_amount"},
                    "total_orders": {"$sum": 1},
                    "first_order": {"$min": "$created_at"},
                    "last_order": {"$max": "$created_at"}
                }
            },
            {
                "$addFields": {
                    "segment": {
                        "$switch": {
                            "branches": [
                                {
                                    "case": {"$gte": ["$total_spent", 1000]},
                                    "then": "VIP"
                                },
                                {
                                    "case": {"$gte": ["$total_spent", 500]},
                                    "then": "Premium"
                                },
                                {
                                    "case": {"$gte": ["$total_spent", 100]},
                                    "then": "Regular"
                                }
                            ],
                            "default": "New"
                        }
                    },
                    "days_since_first": {
                        "$divide": [
                            {"$subtract": ["$last_order", "$first_order"]},
                            86400000  # milliseconds in a day
                        ]
                    }
                }
            },
            {
                "$group": {
                    "_id": "$segment",
                    "customer_count": {"$sum": 1},
                    "total_revenue": {"$sum": "$total_spent"},
                    "average_spent": {"$avg": "$total_spent"},
                    "average_orders": {"$avg": "$total_orders"}
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "segment": "$_id",
                    "customer_count": 1,
                    "total_revenue": {"$round": ["$total_revenue", 2]},
                    "average_spent": {"$round": ["$average_spent", 2]},
                    "average_orders": {"$round": ["$average_orders", 1]}
                }
            },
            {
                "$sort": {"total_revenue": -1}
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def category_trends(self) -> List[Dict[str, Any]]:
        """Analyze product category trends."""
        pipeline = [
            {
                "$unwind": "$items"
            },
            {
                "$group": {
                    "_id": {
                        "category": "$items.category",
                        "month": {"$month": "$created_at"},
                        "year": {"$year": "$created_at"}
                    },
                    "quantity_sold": {"$sum": "$items.quantity"},
                    "revenue": {"$sum": "$items.total"},
                    "orders_count": {"$sum": 1}
                }
            },
            {
                "$group": {
                    "_id": "$_id.category",
                    "total_quantity": {"$sum": "$quantity_sold"},
                    "total_revenue": {"$sum": "$revenue"},
                    "total_orders": {"$sum": "$orders_count"},
                    "monthly_data": {
                        "$push": {
                            "month": "$_id.month",
                            "year": "$_id.year",
                            "quantity": "$quantity_sold",
                            "revenue": "$revenue"
                        }
                    }
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "category": "$_id",
                    "total_quantity": 1,
                    "total_revenue": {"$round": ["$total_revenue", 2]},
                    "total_orders": 1,
                    "average_order_value": {
                        "$round": [
                            {"$divide": ["$total_revenue", "$total_orders"]},
                            2
                        ]
                    }
                }
            },
            {
                "$sort": {"total_revenue": -1}
            }
        ]
        
        return list(self.db.orders.aggregate(pipeline))
    
    def recent_activity(self, days: int = 30) -> Dict[str, Any]:
        """Get recent activity summary."""
        cutoff_date = datetime.now() - timedelta(days=days)
        
        pipeline = [
            {
                "$match": {
                    "created_at": {"$gte": cutoff_date}
                }
            },
            {
                "$group": {
                    "_id": None,
                    "total_orders": {"$sum": 1},
                    "total_revenue": {"$sum": "$total_amount"},
                    "average_order": {"$avg": "$total_amount"},
                    "unique_customers": {"$addToSet": "$customer_id"}
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "period_days": days,
                    "total_orders": 1,
                    "total_revenue": {"$round": ["$total_revenue", 2]},
                    "average_order": {"$round": ["$average_order", 2]},
                    "unique_customers": {"$size": "$unique_customers"}
                }
            }
        ]
        
        result = list(self.db.orders.aggregate(pipeline))
        return result[0] if result else {}
    
    def cleanup(self):
        """Clean up demo data."""
        print("\n🧹 Cleaning up demo data...")
        self.db.orders.drop()
        self.client.close()
        print("✅ Demo data cleaned up")

def main():
    """Main function demonstrating MongoDB aggregation."""
    print("📊 MongoDB Aggregation Example (Python)")
    print("=" * 50)
    
    try:
        # Initialize demo
        demo = MongoAggregationDemo()
        
        # Seed data
        demo.seed_orders_data(200)
        
        # Run aggregation examples
        print("\n📈 Sales by Month")
        print("-" * 30)
        monthly_sales = demo.sales_by_month()
        for month in monthly_sales:
            print(f"{month['year']}-{month['month']:02d}: ${month['total_sales']} ({month['total_orders']} orders)")
        
        print("\n🏆 Top Customers")
        print("-" * 30)
        top_customers = demo.top_customers(5)
        for customer in top_customers:
            print(f"{customer['customer_name']}: ${customer['total_spent']} ({customer['total_orders']} orders)")
        
        print("\n🛍️ Product Performance")
        print("-" * 30)
        products = demo.product_performance()[:5]
        for product in products:
            print(f"{product['product_name']}: ${product['total_revenue']} ({product['total_quantity']} units)")
        
        print("\n🌍 Regional Analysis")
        print("-" * 30)
        regions = demo.regional_analysis()
        for region in regions:
            print(f"{region['region']}: ${region['total_sales']} ({region['total_orders']} orders, {region['unique_customers']} customers)")
        
        print("\n📊 Order Status Breakdown")
        print("-" * 30)
        statuses = demo.order_status_breakdown()
        for status in statuses:
            print(f"{status['status']}: {status['count']} orders (${status['total_value']})")
        
        print("\n👥 Customer Segmentation")
        print("-" * 30)
        segments = demo.customer_segmentation()
        for segment in segments:
            print(f"{segment['segment']}: {segment['customer_count']} customers (${segment['total_revenue']})")
        
        print("\n📂 Category Trends")
        print("-" * 30)
        categories = demo.category_trends()
        for category in categories:
            print(f"{category['category']}: ${category['total_revenue']} ({category['total_quantity']} units)")
        
        print("\n⚡ Recent Activity (Last 30 Days)")
        print("-" * 30)
        recent = demo.recent_activity(30)
        if recent:
            print(f"Orders: {recent['total_orders']}")
            print(f"Revenue: ${recent['total_revenue']}")
            print(f"Customers: {recent['unique_customers']}")
            print(f"Average Order: ${recent['average_order']}")
        
        # Interactive mode
        print("\n" + "=" * 50)
        print("🎯 Interactive Aggregation Demo")
        print("Commands:")
        print("  'monthly' - Sales by month")
        print("  'customers' - Top customers")
        print("  'products' - Product performance")
        print("  'regions' - Regional analysis")
        print("  'status' - Order status breakdown")
        print("  'segments' - Customer segmentation")
        print("  'categories' - Category trends")
        print("  'recent <days>' - Recent activity")
        print("  'cleanup' - Clean up demo data")
        print("  'quit' - Exit")
        print("-" * 50)
        
        while True:
            user_input = input("\n📊 Analytics> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'monthly':
                results = demo.sales_by_month()
                print("📈 Monthly Sales:")
                for result in results:
                    print(f"  {result['year']}-{result['month']:02d}: ${result['total_sales']} ({result['total_orders']} orders)")
            elif user_input.lower() == 'customers':
                results = demo.top_customers(10)
                print("🏆 Top Customers:")
                for result in results:
                    print(f"  {result['customer_name']}: ${result['total_spent']} ({result['total_orders']} orders)")
            elif user_input.lower() == 'products':
                results = demo.product_performance()
                print("🛍️ Product Performance:")
                for result in results:
                    print(f"  {result['product_name']}: ${result['total_revenue']} ({result['total_quantity']} units)")
            elif user_input.lower() == 'regions':
                results = demo.regional_analysis()
                print("🌍 Regional Analysis:")
                for result in results:
                    print(f"  {result['region']}: ${result['total_sales']} ({result['unique_customers']} customers)")
            elif user_input.lower() == 'status':
                results = demo.order_status_breakdown()
                print("📊 Order Status:")
                for result in results:
                    print(f"  {result['status']}: {result['count']} orders (${result['total_value']})")
            elif user_input.lower() == 'segments':
                results = demo.customer_segmentation()
                print("👥 Customer Segments:")
                for result in results:
                    print(f"  {result['segment']}: {result['customer_count']} customers (${result['total_revenue']})")
            elif user_input.lower() == 'categories':
                results = demo.category_trends()
                print("📂 Category Trends:")
                for result in results:
                    print(f"  {result['category']}: ${result['total_revenue']} ({result['total_quantity']} units)")
            elif user_input.startswith('recent '):
                try:
                    days = int(user_input.split(' ', 1)[1])
                    result = demo.recent_activity(days)
                    if result:
                        print(f"⚡ Recent Activity (Last {days} days):")
                        print(f"  Orders: {result['total_orders']}")
                        print(f"  Revenue: ${result['total_revenue']}")
                        print(f"  Customers: {result['unique_customers']}")
                        print(f"  Average Order: ${result['average_order']}")
                    else:
                        print("No recent activity found")
                except ValueError:
                    print("Please provide a valid number of days")
            elif user_input.lower() == 'cleanup':
                demo.cleanup()
                print("✅ Demo data cleaned up")
                break
            elif user_input:
                print("Unknown command. Type 'quit' to exit.")
        
        # Final cleanup
        if user_input.lower() != 'cleanup':
            demo.cleanup()
        
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()