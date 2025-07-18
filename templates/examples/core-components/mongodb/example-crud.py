#!/usr/bin/env python3
"""
MongoDB CRUD Example (Python)

This example demonstrates MongoDB CRUD operations using PyMongo
with proper error handling and connection management.
"""

import os
import sys
from typing import Any, Dict, List, Optional
from datetime import datetime
from dataclasses import dataclass, asdict
from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.errors import ConnectionFailure, DuplicateKeyError, PyMongoError
from bson import ObjectId
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

@dataclass
class User:
    """User data model."""
    username: str
    email: str
    age: int
    role: str = "user"
    created_at: datetime = None
    updated_at: datetime = None
    _id: Optional[ObjectId] = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()

@dataclass
class Product:
    """Product data model."""
    name: str
    price: float
    category: str
    description: str = ""
    in_stock: bool = True
    tags: List[str] = None
    created_at: datetime = None
    _id: Optional[ObjectId] = None
    
    def __post_init__(self):
        if self.tags is None:
            self.tags = []
        if self.created_at is None:
            self.created_at = datetime.now()

class MongoDBClient:
    """MongoDB client with CRUD operations."""
    
    def __init__(self, connection_string: str = None, database_name: str = "spinbox_demo"):
        """Initialize MongoDB client."""
        
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
    
    def create_indexes(self):
        """Create indexes for better performance."""
        try:
            # Users collection indexes
            users_collection = self.db.users
            users_collection.create_index([("username", ASCENDING)], unique=True)
            users_collection.create_index([("email", ASCENDING)], unique=True)
            users_collection.create_index([("created_at", DESCENDING)])
            
            # Products collection indexes
            products_collection = self.db.products
            products_collection.create_index([("name", ASCENDING)])
            products_collection.create_index([("category", ASCENDING)])
            products_collection.create_index([("price", ASCENDING)])
            products_collection.create_index([("tags", ASCENDING)])
            
            print("✅ Indexes created successfully")
            
        except Exception as e:
            print(f"❌ Error creating indexes: {e}")
    
    def insert_user(self, user: User) -> Optional[ObjectId]:
        """Insert a new user."""
        try:
            user_dict = asdict(user)
            
            # Remove None _id for insertion
            if user_dict.get("_id") is None:
                user_dict.pop("_id", None)
            
            result = self.db.users.insert_one(user_dict)
            print(f"✅ User {user.username} inserted with ID: {result.inserted_id}")
            return result.inserted_id
            
        except DuplicateKeyError as e:
            print(f"❌ User {user.username} already exists: {e}")
            return None
        except Exception as e:
            print(f"❌ Error inserting user: {e}")
            return None
    
    def get_user(self, user_id: str = None, username: str = None) -> Optional[Dict[str, Any]]:
        """Get user by ID or username."""
        try:
            query = {}
            if user_id:
                query["_id"] = ObjectId(user_id)
            elif username:
                query["username"] = username
            else:
                return None
            
            user = self.db.users.find_one(query)
            
            if user:
                print(f"✅ Found user: {user.get('username')}")
            else:
                print("❌ User not found")
            
            return user
            
        except Exception as e:
            print(f"❌ Error getting user: {e}")
            return None
    
    def get_users(self, limit: int = 10, skip: int = 0, sort_by: str = "created_at") -> List[Dict[str, Any]]:
        """Get multiple users with pagination."""
        try:
            sort_direction = DESCENDING if sort_by == "created_at" else ASCENDING
            
            users = list(self.db.users.find()
                        .sort(sort_by, sort_direction)
                        .skip(skip)
                        .limit(limit))
            
            print(f"✅ Found {len(users)} users")
            return users
            
        except Exception as e:
            print(f"❌ Error getting users: {e}")
            return []
    
    def update_user(self, user_id: str, updates: Dict[str, Any]) -> bool:
        """Update user by ID."""
        try:
            # Add updated_at timestamp
            updates["updated_at"] = datetime.now()
            
            result = self.db.users.update_one(
                {"_id": ObjectId(user_id)},
                {"$set": updates}
            )
            
            if result.modified_count > 0:
                print(f"✅ User {user_id} updated successfully")
                return True
            else:
                print(f"❌ No user found with ID: {user_id}")
                return False
                
        except Exception as e:
            print(f"❌ Error updating user: {e}")
            return False
    
    def delete_user(self, user_id: str) -> bool:
        """Delete user by ID."""
        try:
            result = self.db.users.delete_one({"_id": ObjectId(user_id)})
            
            if result.deleted_count > 0:
                print(f"✅ User {user_id} deleted successfully")
                return True
            else:
                print(f"❌ No user found with ID: {user_id}")
                return False
                
        except Exception as e:
            print(f"❌ Error deleting user: {e}")
            return False
    
    def insert_product(self, product: Product) -> Optional[ObjectId]:
        """Insert a new product."""
        try:
            product_dict = asdict(product)
            
            # Remove None _id for insertion
            if product_dict.get("_id") is None:
                product_dict.pop("_id", None)
            
            result = self.db.products.insert_one(product_dict)
            print(f"✅ Product {product.name} inserted with ID: {result.inserted_id}")
            return result.inserted_id
            
        except Exception as e:
            print(f"❌ Error inserting product: {e}")
            return None
    
    def get_products(self, 
                    category: str = None, 
                    min_price: float = None, 
                    max_price: float = None,
                    in_stock: bool = None,
                    limit: int = 10) -> List[Dict[str, Any]]:
        """Get products with filtering."""
        try:
            query = {}
            
            # Build query filters
            if category:
                query["category"] = category
            if min_price is not None or max_price is not None:
                price_filter = {}
                if min_price is not None:
                    price_filter["$gte"] = min_price
                if max_price is not None:
                    price_filter["$lte"] = max_price
                query["price"] = price_filter
            if in_stock is not None:
                query["in_stock"] = in_stock
            
            products = list(self.db.products.find(query).limit(limit))
            
            print(f"✅ Found {len(products)} products")
            return products
            
        except Exception as e:
            print(f"❌ Error getting products: {e}")
            return []
    
    def search_products(self, search_term: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search products by name or description."""
        try:
            # Create text search query
            query = {
                "$or": [
                    {"name": {"$regex": search_term, "$options": "i"}},
                    {"description": {"$regex": search_term, "$options": "i"}},
                    {"tags": {"$regex": search_term, "$options": "i"}}
                ]
            }
            
            products = list(self.db.products.find(query).limit(limit))
            
            print(f"✅ Found {len(products)} products matching '{search_term}'")
            return products
            
        except Exception as e:
            print(f"❌ Error searching products: {e}")
            return []
    
    def get_categories(self) -> List[str]:
        """Get all product categories."""
        try:
            categories = self.db.products.distinct("category")
            print(f"✅ Found {len(categories)} categories")
            return categories
            
        except Exception as e:
            print(f"❌ Error getting categories: {e}")
            return []
    
    def get_collection_stats(self, collection_name: str) -> Dict[str, Any]:
        """Get statistics for a collection."""
        try:
            stats = self.db.command("collStats", collection_name)
            
            return {
                "count": stats.get("count", 0),
                "size": stats.get("size", 0),
                "avgObjSize": stats.get("avgObjSize", 0),
                "storageSize": stats.get("storageSize", 0),
                "indexes": stats.get("nindexes", 0)
            }
            
        except Exception as e:
            print(f"❌ Error getting collection stats: {e}")
            return {}
    
    def drop_collection(self, collection_name: str) -> bool:
        """Drop a collection."""
        try:
            self.db.drop_collection(collection_name)
            print(f"✅ Collection {collection_name} dropped")
            return True
            
        except Exception as e:
            print(f"❌ Error dropping collection: {e}")
            return False
    
    def close(self):
        """Close the MongoDB connection."""
        try:
            self.client.close()
            print("✅ MongoDB connection closed")
        except Exception as e:
            print(f"❌ Error closing connection: {e}")

class MongoDBDemo:
    """MongoDB CRUD operations demonstration."""
    
    def __init__(self):
        """Initialize the demo."""
        self.client = MongoDBClient()
        self.client.create_indexes()
    
    def seed_data(self):
        """Seed database with sample data."""
        print("\n🌱 Seeding sample data...")
        
        # Sample users
        users = [
            User(username="alice", email="alice@example.com", age=25, role="admin"),
            User(username="bob", email="bob@example.com", age=30, role="user"),
            User(username="charlie", email="charlie@example.com", age=35, role="user"),
            User(username="diana", email="diana@example.com", age=28, role="moderator")
        ]
        
        user_ids = []
        for user in users:
            user_id = self.client.insert_user(user)
            if user_id:
                user_ids.append(user_id)
        
        # Sample products
        products = [
            Product(name="Laptop", price=999.99, category="Electronics", 
                   description="High-performance laptop", tags=["computer", "work"]),
            Product(name="Coffee Mug", price=15.99, category="Kitchen", 
                   description="Ceramic coffee mug", tags=["coffee", "ceramic"]),
            Product(name="Python Book", price=39.99, category="Books", 
                   description="Learn Python programming", tags=["python", "programming"]),
            Product(name="Wireless Mouse", price=29.99, category="Electronics", 
                   description="Ergonomic wireless mouse", tags=["mouse", "wireless"]),
            Product(name="Notebook", price=8.99, category="Office", 
                   description="Lined notebook for writing", tags=["writing", "paper"])
        ]
        
        product_ids = []
        for product in products:
            product_id = self.client.insert_product(product)
            if product_id:
                product_ids.append(product_id)
        
        return user_ids, product_ids
    
    def demo_user_operations(self):
        """Demonstrate user CRUD operations."""
        print("\n👤 User Operations Demo")
        print("-" * 30)
        
        # Get all users
        users = self.client.get_users(limit=5)
        print(f"📋 Users in database: {len(users)}")
        
        if users:
            # Get first user
            first_user = users[0]
            user_id = str(first_user["_id"])
            
            # Update user
            updates = {"age": 26, "role": "super_admin"}
            self.client.update_user(user_id, updates)
            
            # Get updated user
            updated_user = self.client.get_user(user_id=user_id)
            if updated_user:
                print(f"📄 Updated user: {updated_user['username']} - Age: {updated_user['age']}")
    
    def demo_product_operations(self):
        """Demonstrate product CRUD operations."""
        print("\n🛍️ Product Operations Demo")
        print("-" * 30)
        
        # Get products by category
        electronics = self.client.get_products(category="Electronics")
        print(f"💻 Electronics products: {len(electronics)}")
        
        # Search products
        search_results = self.client.search_products("python")
        print(f"🔍 Search results for 'python': {len(search_results)}")
        
        # Get products by price range
        affordable_products = self.client.get_products(min_price=10, max_price=50)
        print(f"💰 Products $10-$50: {len(affordable_products)}")
        
        # Get all categories
        categories = self.client.get_categories()
        print(f"📂 Product categories: {', '.join(categories)}")
    
    def demo_aggregation(self):
        """Demonstrate aggregation operations."""
        print("\n📊 Aggregation Demo")
        print("-" * 30)
        
        # User statistics by role
        user_stats = list(self.client.db.users.aggregate([
            {"$group": {"_id": "$role", "count": {"$sum": 1}, "avg_age": {"$avg": "$age"}}},
            {"$sort": {"count": -1}}
        ]))
        
        print("👥 User statistics by role:")
        for stat in user_stats:
            print(f"  {stat['_id']}: {stat['count']} users, avg age: {stat['avg_age']:.1f}")
        
        # Product statistics by category
        product_stats = list(self.client.db.products.aggregate([
            {"$group": {
                "_id": "$category", 
                "count": {"$sum": 1}, 
                "avg_price": {"$avg": "$price"},
                "total_value": {"$sum": "$price"}
            }},
            {"$sort": {"total_value": -1}}
        ]))
        
        print("\n🛍️ Product statistics by category:")
        for stat in product_stats:
            print(f"  {stat['_id']}: {stat['count']} products, avg: ${stat['avg_price']:.2f}, total: ${stat['total_value']:.2f}")
    
    def demo_advanced_queries(self):
        """Demonstrate advanced query operations."""
        print("\n🔍 Advanced Queries Demo")
        print("-" * 30)
        
        # Find users created in the last hour
        recent_users = list(self.client.db.users.find({
            "created_at": {"$gte": datetime.now().replace(hour=0, minute=0, second=0)}
        }))
        print(f"🕐 Users created today: {len(recent_users)}")
        
        # Find products with specific tags
        tagged_products = list(self.client.db.products.find({
            "tags": {"$in": ["computer", "programming"]}
        }))
        print(f"🏷️ Products with 'computer' or 'programming' tags: {len(tagged_products)}")
        
        # Find products not in stock
        out_of_stock = list(self.client.db.products.find({
            "in_stock": False
        }))
        print(f"❌ Out of stock products: {len(out_of_stock)}")
    
    def cleanup(self):
        """Clean up demo data."""
        print("\n🧹 Cleaning up demo data...")
        
        # Drop collections
        self.client.drop_collection("users")
        self.client.drop_collection("products")
        
        # Close connection
        self.client.close()

def main():
    """Main function demonstrating MongoDB CRUD operations."""
    print("🍃 MongoDB CRUD Example (Python)")
    print("=" * 50)
    
    try:
        # Initialize demo
        demo = MongoDBDemo()
        
        # Seed data
        user_ids, product_ids = demo.seed_data()
        
        # Demo operations
        demo.demo_user_operations()
        demo.demo_product_operations()
        demo.demo_aggregation()
        demo.demo_advanced_queries()
        
        # Show collection stats
        print("\n📊 Collection Statistics")
        print("-" * 30)
        user_stats = demo.client.get_collection_stats("users")
        product_stats = demo.client.get_collection_stats("products")
        
        print(f"👥 Users: {user_stats.get('count', 0)} documents")
        print(f"🛍️ Products: {product_stats.get('count', 0)} documents")
        
        # Interactive mode
        print("\n" + "=" * 50)
        print("🎯 Interactive MongoDB Demo")
        print("Commands:")
        print("  'users' - List all users")
        print("  'products' - List all products")
        print("  'search <term>' - Search products")
        print("  'category <name>' - Get products by category")
        print("  'stats' - Show collection statistics")
        print("  'cleanup' - Clean up demo data")
        print("  'quit' - Exit")
        print("-" * 50)
        
        while True:
            user_input = input("\n🍃 MongoDB> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'users':
                users = demo.client.get_users(limit=10)
                print(f"👥 Users ({len(users)}):")
                for user in users:
                    print(f"  - {user['username']} ({user['email']}) - {user['role']}")
            elif user_input.lower() == 'products':
                products = demo.client.get_products(limit=10)
                print(f"🛍️ Products ({len(products)}):")
                for product in products:
                    print(f"  - {product['name']} - ${product['price']:.2f} ({product['category']})")
            elif user_input.startswith('search '):
                term = user_input.split(' ', 1)[1]
                products = demo.client.search_products(term)
                print(f"🔍 Search results for '{term}' ({len(products)}):")
                for product in products:
                    print(f"  - {product['name']} - ${product['price']:.2f}")
            elif user_input.startswith('category '):
                category = user_input.split(' ', 1)[1]
                products = demo.client.get_products(category=category)
                print(f"📂 Products in '{category}' ({len(products)}):")
                for product in products:
                    print(f"  - {product['name']} - ${product['price']:.2f}")
            elif user_input.lower() == 'stats':
                user_stats = demo.client.get_collection_stats("users")
                product_stats = demo.client.get_collection_stats("products")
                print("📊 Collection Statistics:")
                print(f"  Users: {user_stats.get('count', 0)} documents")
                print(f"  Products: {product_stats.get('count', 0)} documents")
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