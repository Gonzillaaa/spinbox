#!/usr/bin/env python3
"""
Chroma Basic Operations Example (Python)

This example demonstrates basic Chroma vector database operations
including document storage, embeddings, and similarity search.
"""

import os
import sys
import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import datetime
import chromadb
from chromadb.config import Settings
from chromadb.utils import embedding_functions
from dotenv import load_dotenv
import numpy as np

# Load environment variables
load_dotenv()

class ChromaClient:
    """Chroma vector database client for basic operations."""
    
    def __init__(self, 
                 persist_directory: str = "./chroma_data",
                 embedding_function: str = "sentence-transformers"):
        """Initialize Chroma client."""
        
        self.persist_directory = persist_directory
        
        # Initialize Chroma client with persistence
        self.client = chromadb.PersistentClient(
            path=persist_directory,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # Set up embedding function
        if embedding_function == "sentence-transformers":
            self.embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name="all-MiniLM-L6-v2"
            )
        elif embedding_function == "openai":
            openai_key = os.getenv("OPENAI_API_KEY")
            if not openai_key:
                print("⚠️ OpenAI API key not found, using sentence-transformers")
                self.embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(
                    model_name="all-MiniLM-L6-v2"
                )
            else:
                self.embedding_function = embedding_functions.OpenAIEmbeddingFunction(
                    api_key=openai_key,
                    model_name="text-embedding-ada-002"
                )
        else:
            # Default embedding function
            self.embedding_function = embedding_functions.DefaultEmbeddingFunction()
        
        print(f"✅ Chroma client initialized with {embedding_function} embeddings")
        print(f"📁 Persist directory: {persist_directory}")
        
        # Store collections
        self.collections = {}
    
    def create_collection(self, name: str, metadata: Dict[str, Any] = None) -> bool:
        """Create a new collection."""
        try:
            if metadata is None:
                metadata = {"created_at": datetime.now().isoformat()}
            
            collection = self.client.create_collection(
                name=name,
                embedding_function=self.embedding_function,
                metadata=metadata
            )
            
            self.collections[name] = collection
            print(f"✅ Collection '{name}' created successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error creating collection '{name}': {e}")
            return False
    
    def get_collection(self, name: str):
        """Get an existing collection."""
        try:
            if name not in self.collections:
                collection = self.client.get_collection(
                    name=name,
                    embedding_function=self.embedding_function
                )
                self.collections[name] = collection
            
            return self.collections[name]
            
        except Exception as e:
            print(f"❌ Error getting collection '{name}': {e}")
            return None
    
    def get_or_create_collection(self, name: str, metadata: Dict[str, Any] = None):
        """Get or create a collection."""
        try:
            if metadata is None:
                metadata = {"created_at": datetime.now().isoformat()}
            
            collection = self.client.get_or_create_collection(
                name=name,
                embedding_function=self.embedding_function,
                metadata=metadata
            )
            
            self.collections[name] = collection
            print(f"✅ Collection '{name}' ready")
            return collection
            
        except Exception as e:
            print(f"❌ Error with collection '{name}': {e}")
            return None
    
    def add_documents(self, 
                     collection_name: str, 
                     documents: List[str], 
                     metadata: List[Dict[str, Any]] = None,
                     ids: List[str] = None) -> bool:
        """Add documents to a collection."""
        try:
            collection = self.get_collection(collection_name)
            if not collection:
                print(f"❌ Collection '{collection_name}' not found")
                return False
            
            # Generate IDs if not provided
            if ids is None:
                ids = [str(uuid.uuid4()) for _ in documents]
            
            # Add metadata if not provided
            if metadata is None:
                metadata = [{"added_at": datetime.now().isoformat()} for _ in documents]
            
            # Add documents
            collection.add(
                documents=documents,
                metadatas=metadata,
                ids=ids
            )
            
            print(f"✅ Added {len(documents)} documents to '{collection_name}'")
            return True
            
        except Exception as e:
            print(f"❌ Error adding documents to '{collection_name}': {e}")
            return False
    
    def query_documents(self, 
                       collection_name: str, 
                       query_texts: List[str], 
                       n_results: int = 5,
                       where: Dict[str, Any] = None) -> Dict[str, Any]:
        """Query documents by similarity."""
        try:
            collection = self.get_collection(collection_name)
            if not collection:
                print(f"❌ Collection '{collection_name}' not found")
                return {}
            
            # Query the collection
            results = collection.query(
                query_texts=query_texts,
                n_results=n_results,
                where=where
            )
            
            print(f"✅ Found {len(results['ids'][0])} results for query")
            return results
            
        except Exception as e:
            print(f"❌ Error querying '{collection_name}': {e}")
            return {}
    
    def get_documents(self, 
                     collection_name: str, 
                     ids: List[str] = None,
                     where: Dict[str, Any] = None,
                     limit: int = None) -> Dict[str, Any]:
        """Get documents from a collection."""
        try:
            collection = self.get_collection(collection_name)
            if not collection:
                print(f"❌ Collection '{collection_name}' not found")
                return {}
            
            # Get documents
            results = collection.get(
                ids=ids,
                where=where,
                limit=limit
            )
            
            print(f"✅ Retrieved {len(results['ids'])} documents")
            return results
            
        except Exception as e:
            print(f"❌ Error getting documents from '{collection_name}': {e}")
            return {}
    
    def update_documents(self, 
                        collection_name: str, 
                        ids: List[str],
                        documents: List[str] = None,
                        metadata: List[Dict[str, Any]] = None) -> bool:
        """Update documents in a collection."""
        try:
            collection = self.get_collection(collection_name)
            if not collection:
                print(f"❌ Collection '{collection_name}' not found")
                return False
            
            # Update documents
            collection.update(
                ids=ids,
                documents=documents,
                metadatas=metadata
            )
            
            print(f"✅ Updated {len(ids)} documents in '{collection_name}'")
            return True
            
        except Exception as e:
            print(f"❌ Error updating documents in '{collection_name}': {e}")
            return False
    
    def delete_documents(self, collection_name: str, ids: List[str]) -> bool:
        """Delete documents from a collection."""
        try:
            collection = self.get_collection(collection_name)
            if not collection:
                print(f"❌ Collection '{collection_name}' not found")
                return False
            
            # Delete documents
            collection.delete(ids=ids)
            
            print(f"✅ Deleted {len(ids)} documents from '{collection_name}'")
            return True
            
        except Exception as e:
            print(f"❌ Error deleting documents from '{collection_name}': {e}")
            return False
    
    def get_collection_info(self, collection_name: str) -> Dict[str, Any]:
        """Get information about a collection."""
        try:
            collection = self.get_collection(collection_name)
            if not collection:
                print(f"❌ Collection '{collection_name}' not found")
                return {}
            
            # Get collection info
            count = collection.count()
            metadata = collection.metadata
            
            return {
                "name": collection_name,
                "count": count,
                "metadata": metadata
            }
            
        except Exception as e:
            print(f"❌ Error getting collection info: {e}")
            return {}
    
    def list_collections(self) -> List[str]:
        """List all collections."""
        try:
            collections = self.client.list_collections()
            collection_names = [c.name for c in collections]
            print(f"✅ Found {len(collection_names)} collections")
            return collection_names
            
        except Exception as e:
            print(f"❌ Error listing collections: {e}")
            return []
    
    def delete_collection(self, name: str) -> bool:
        """Delete a collection."""
        try:
            self.client.delete_collection(name=name)
            if name in self.collections:
                del self.collections[name]
            
            print(f"✅ Collection '{name}' deleted")
            return True
            
        except Exception as e:
            print(f"❌ Error deleting collection '{name}': {e}")
            return False
    
    def reset_database(self) -> bool:
        """Reset the entire database."""
        try:
            self.client.reset()
            self.collections = {}
            print("✅ Database reset successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error resetting database: {e}")
            return False

class ChromaDemo:
    """Chroma basic operations demonstration."""
    
    def __init__(self):
        """Initialize the demo."""
        self.client = ChromaClient()
        self.collection_name = "demo_documents"
    
    def seed_sample_data(self):
        """Seed the database with sample documents."""
        print("\n🌱 Seeding sample data...")
        
        # Create collection
        self.client.get_or_create_collection(
            self.collection_name,
            metadata={"description": "Demo collection for basic operations"}
        )
        
        # Sample documents
        documents = [
            "Python is a high-level programming language known for its simplicity and readability.",
            "Machine learning is a subset of artificial intelligence that enables computers to learn from data.",
            "Natural language processing allows computers to understand and process human language.",
            "Web development involves creating websites and web applications using various technologies.",
            "Data science combines statistics, programming, and domain expertise to extract insights from data.",
            "Cloud computing provides on-demand access to computing resources over the internet.",
            "DevOps practices combine software development and IT operations to improve deployment speed.",
            "Cybersecurity protects digital systems and data from unauthorized access and threats.",
            "Blockchain technology enables secure, decentralized transactions and record-keeping.",
            "Artificial intelligence aims to create machines that can perform tasks requiring human intelligence."
        ]
        
        # Document metadata
        metadata = [
            {"category": "programming", "topic": "python", "difficulty": "beginner"},
            {"category": "ai", "topic": "machine_learning", "difficulty": "intermediate"},
            {"category": "ai", "topic": "nlp", "difficulty": "intermediate"},
            {"category": "programming", "topic": "web_development", "difficulty": "beginner"},
            {"category": "data", "topic": "data_science", "difficulty": "intermediate"},
            {"category": "infrastructure", "topic": "cloud", "difficulty": "intermediate"},
            {"category": "infrastructure", "topic": "devops", "difficulty": "advanced"},
            {"category": "security", "topic": "cybersecurity", "difficulty": "advanced"},
            {"category": "blockchain", "topic": "blockchain", "difficulty": "advanced"},
            {"category": "ai", "topic": "artificial_intelligence", "difficulty": "advanced"}
        ]
        
        # Add documents
        success = self.client.add_documents(
            self.collection_name,
            documents,
            metadata=metadata
        )
        
        if success:
            print(f"✅ Seeded {len(documents)} documents")
        
        return success
    
    def demo_basic_queries(self):
        """Demonstrate basic query operations."""
        print("\n🔍 Basic Query Operations")
        print("-" * 30)
        
        # Simple similarity search
        query_texts = ["What is programming?"]
        results = self.client.query_documents(
            self.collection_name,
            query_texts,
            n_results=3
        )
        
        if results:
            print(f"Query: {query_texts[0]}")
            print("Top 3 results:")
            for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
                print(f"  {i+1}. {doc[:80]}...")
                print(f"     Category: {metadata.get('category', 'N/A')}")
                print()
    
    def demo_filtered_search(self):
        """Demonstrate filtered search operations."""
        print("\n🎯 Filtered Search Operations")
        print("-" * 30)
        
        # Search with category filter
        query_texts = ["artificial intelligence"]
        results = self.client.query_documents(
            self.collection_name,
            query_texts,
            n_results=5,
            where={"category": "ai"}
        )
        
        if results:
            print(f"Query: {query_texts[0]} (AI category only)")
            print("Results:")
            for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
                print(f"  {i+1}. {doc[:80]}...")
                print(f"     Topic: {metadata.get('topic', 'N/A')}")
                print()
    
    def demo_metadata_operations(self):
        """Demonstrate metadata-based operations."""
        print("\n📊 Metadata Operations")
        print("-" * 30)
        
        # Get all beginner documents
        results = self.client.get_documents(
            self.collection_name,
            where={"difficulty": "beginner"}
        )
        
        if results:
            print("Beginner-level documents:")
            for i, (doc, metadata) in enumerate(zip(results['documents'], results['metadatas'])):
                print(f"  {i+1}. {doc[:60]}...")
                print(f"     Category: {metadata.get('category', 'N/A')}")
                print()
    
    def demo_document_management(self):
        """Demonstrate document management operations."""
        print("\n📝 Document Management")
        print("-" * 30)
        
        # Add a new document
        new_doc = "Quantum computing uses quantum mechanical phenomena to perform calculations."
        new_metadata = {"category": "quantum", "topic": "quantum_computing", "difficulty": "advanced"}
        
        success = self.client.add_documents(
            self.collection_name,
            [new_doc],
            metadata=[new_metadata],
            ids=["quantum_doc_1"]
        )
        
        if success:
            print("✅ Added quantum computing document")
            
            # Query for it
            results = self.client.query_documents(
                self.collection_name,
                ["quantum computing"],
                n_results=1
            )
            
            if results:
                print("Found the new document:")
                print(f"  {results['documents'][0][0]}")
                print()
            
            # Update the document
            updated_doc = "Quantum computing leverages quantum mechanical phenomena like superposition and entanglement to perform complex calculations."
            updated_metadata = {"category": "quantum", "topic": "quantum_computing", "difficulty": "expert", "updated": True}
            
            success = self.client.update_documents(
                self.collection_name,
                ["quantum_doc_1"],
                [updated_doc],
                [updated_metadata]
            )
            
            if success:
                print("✅ Updated quantum computing document")
    
    def demo_collection_info(self):
        """Demonstrate collection information retrieval."""
        print("\n📋 Collection Information")
        print("-" * 30)
        
        # Get collection info
        info = self.client.get_collection_info(self.collection_name)
        
        if info:
            print(f"Collection: {info['name']}")
            print(f"Document count: {info['count']}")
            print(f"Metadata: {info['metadata']}")
            print()
        
        # List all collections
        collections = self.client.list_collections()
        print(f"All collections: {', '.join(collections)}")
    
    def cleanup(self):
        """Clean up demo data."""
        print("\n🧹 Cleaning up demo data...")
        
        # Delete the demo collection
        success = self.client.delete_collection(self.collection_name)
        
        if success:
            print("✅ Demo collection deleted")

def main():
    """Main function demonstrating Chroma basic operations."""
    print("🔮 Chroma Basic Operations Example (Python)")
    print("=" * 50)
    
    try:
        # Initialize demo
        demo = ChromaDemo()
        
        # Seed sample data
        if not demo.seed_sample_data():
            print("❌ Failed to seed data")
            return
        
        # Run demonstrations
        demo.demo_basic_queries()
        demo.demo_filtered_search()
        demo.demo_metadata_operations()
        demo.demo_document_management()
        demo.demo_collection_info()
        
        # Interactive mode
        print("\n" + "=" * 50)
        print("🎯 Interactive Chroma Demo")
        print("Commands:")
        print("  'query <text>' - Search for similar documents")
        print("  'filter <category>' - Filter by category")
        print("  'add <text>' - Add a new document")
        print("  'count' - Get document count")
        print("  'collections' - List all collections")
        print("  'info' - Show collection information")
        print("  'cleanup' - Clean up demo data")
        print("  'quit' - Exit")
        print("-" * 50)
        
        while True:
            user_input = input("\n🔮 Chroma> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'count':
                info = demo.client.get_collection_info(demo.collection_name)
                if info:
                    print(f"📊 Document count: {info['count']}")
            elif user_input.lower() == 'collections':
                collections = demo.client.list_collections()
                print(f"📚 Collections: {', '.join(collections) if collections else 'None'}")
            elif user_input.lower() == 'info':
                info = demo.client.get_collection_info(demo.collection_name)
                if info:
                    print(f"📋 Collection: {info['name']}")
                    print(f"📊 Count: {info['count']}")
                    print(f"📝 Metadata: {info['metadata']}")
            elif user_input.startswith('query '):
                query_text = user_input[6:]
                results = demo.client.query_documents(
                    demo.collection_name,
                    [query_text],
                    n_results=3
                )
                if results and results['documents'][0]:
                    print(f"🔍 Results for '{query_text}':")
                    for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
                        print(f"  {i+1}. {doc[:80]}...")
                        print(f"     Category: {metadata.get('category', 'N/A')}")
                else:
                    print("❌ No results found")
            elif user_input.startswith('filter '):
                category = user_input[7:]
                results = demo.client.get_documents(
                    demo.collection_name,
                    where={"category": category}
                )
                if results and results['documents']:
                    print(f"📂 Documents in '{category}' category:")
                    for i, (doc, metadata) in enumerate(zip(results['documents'], results['metadatas'])):
                        print(f"  {i+1}. {doc[:80]}...")
                else:
                    print(f"❌ No documents found in '{category}' category")
            elif user_input.startswith('add '):
                text = user_input[4:]
                success = demo.client.add_documents(
                    demo.collection_name,
                    [text],
                    metadata=[{"category": "user_added", "added_by": "interactive"}]
                )
                if success:
                    print("✅ Document added successfully")
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