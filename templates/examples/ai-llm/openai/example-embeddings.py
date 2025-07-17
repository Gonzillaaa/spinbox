"""
OpenAI Embeddings Example
Text embeddings for similarity search and semantic analysis.

Features:
- Text embedding generation
- Similarity calculation
- Batch processing
- Caching for efficiency
- Vector operations

Setup:
1. pip install openai python-dotenv numpy scikit-learn
2. Set OPENAI_API_KEY environment variable
3. python example-embeddings.py

Environment variables:
- OPENAI_API_KEY: Your OpenAI API key
- OPENAI_EMBEDDING_MODEL: Model to use (default: text-embedding-ada-002)
"""

import os
import sys
import numpy as np
from openai import OpenAI
from dotenv import load_dotenv
from typing import List, Dict, Any, Tuple
import json
import time
from sklearn.metrics.pairwise import cosine_similarity
import pickle
import hashlib

# Load environment variables
load_dotenv()

class OpenAIEmbeddingsClient:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY environment variable is required")
        
        self.client = OpenAI(api_key=self.api_key)
        self.model = os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-ada-002")
        
        # Cost tracking
        self.total_tokens = 0
        self.total_cost = 0.0
        self.request_count = 0
        
        # Embedding model pricing (per 1K tokens)
        self.pricing = {
            "text-embedding-ada-002": 0.0001,
            "text-embedding-3-small": 0.00002,
            "text-embedding-3-large": 0.00013
        }
        
        # Cache for embeddings
        self.cache = {}
        self.cache_file = "embeddings_cache.pkl"
        self.load_cache()
        
        print(f"OpenAI Embeddings Client initialized with model: {self.model}")
    
    def count_tokens(self, text: str) -> int:
        """Estimate token count for text"""
        # Rough estimation: 1 token ≈ 4 characters
        return len(text) // 4
    
    def calculate_cost(self, tokens: int) -> float:
        """Calculate cost based on token usage"""
        rate = self.pricing.get(self.model, 0.0001)
        return (tokens / 1000) * rate
    
    def load_cache(self):
        """Load embeddings cache from file"""
        try:
            with open(self.cache_file, 'rb') as f:
                self.cache = pickle.load(f)
            print(f"Loaded {len(self.cache)} cached embeddings")
        except FileNotFoundError:
            self.cache = {}
    
    def save_cache(self):
        """Save embeddings cache to file"""
        with open(self.cache_file, 'wb') as f:
            pickle.dump(self.cache, f)
    
    def get_cache_key(self, text: str) -> str:
        """Generate cache key for text"""
        return hashlib.md5(f"{self.model}:{text}".encode()).hexdigest()
    
    def get_embedding(self, text: str, use_cache: bool = True) -> Dict[str, Any]:
        """Get embedding for a single text"""
        # Check cache first
        cache_key = self.get_cache_key(text)
        if use_cache and cache_key in self.cache:
            return {
                "embedding": self.cache[cache_key],
                "tokens_used": 0,
                "cost": 0.0,
                "cached": True
            }
        
        try:
            # Count tokens
            tokens = self.count_tokens(text)
            
            # Get embedding
            response = self.client.embeddings.create(
                input=text,
                model=self.model
            )
            
            embedding = response.data[0].embedding
            cost = self.calculate_cost(tokens)
            
            # Update tracking
            self.total_tokens += tokens
            self.total_cost += cost
            self.request_count += 1
            
            # Cache the result
            if use_cache:
                self.cache[cache_key] = embedding
                self.save_cache()
            
            return {
                "embedding": embedding,
                "tokens_used": tokens,
                "cost": cost,
                "cached": False
            }
            
        except Exception as e:
            return {
                "error": str(e),
                "embedding": None,
                "tokens_used": 0,
                "cost": 0.0
            }
    
    def get_embeddings_batch(self, texts: List[str], batch_size: int = 100) -> List[Dict[str, Any]]:
        """Get embeddings for multiple texts in batches"""
        results = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            
            try:
                # Count tokens for batch
                total_tokens = sum(self.count_tokens(text) for text in batch)
                
                # Get embeddings
                response = self.client.embeddings.create(
                    input=batch,
                    model=self.model
                )
                
                cost = self.calculate_cost(total_tokens)
                
                # Update tracking
                self.total_tokens += total_tokens
                self.total_cost += cost
                self.request_count += 1
                
                # Process results
                for j, embedding_data in enumerate(response.data):
                    text = batch[j]
                    embedding = embedding_data.embedding
                    
                    # Cache the result
                    cache_key = self.get_cache_key(text)
                    self.cache[cache_key] = embedding
                    
                    results.append({
                        "text": text,
                        "embedding": embedding,
                        "tokens_used": self.count_tokens(text),
                        "cost": cost / len(batch),  # Distribute cost evenly
                        "cached": False
                    })
                
                # Save cache periodically
                if i % (batch_size * 5) == 0:
                    self.save_cache()
                    
            except Exception as e:
                # Add error results for this batch
                for text in batch:
                    results.append({
                        "text": text,
                        "embedding": None,
                        "tokens_used": 0,
                        "cost": 0.0,
                        "error": str(e)
                    })
        
        # Save final cache
        self.save_cache()
        return results
    
    def calculate_similarity(self, text1: str, text2: str) -> Dict[str, Any]:
        """Calculate similarity between two texts"""
        # Get embeddings
        result1 = self.get_embedding(text1)
        result2 = self.get_embedding(text2)
        
        if result1.get("error") or result2.get("error"):
            return {
                "error": "Failed to get embeddings",
                "similarity": None,
                "details": {
                    "text1_error": result1.get("error"),
                    "text2_error": result2.get("error")
                }
            }
        
        # Calculate cosine similarity
        embedding1 = np.array(result1["embedding"]).reshape(1, -1)
        embedding2 = np.array(result2["embedding"]).reshape(1, -1)
        
        similarity = cosine_similarity(embedding1, embedding2)[0][0]
        
        return {
            "similarity": float(similarity),
            "tokens_used": result1["tokens_used"] + result2["tokens_used"],
            "cost": result1["cost"] + result2["cost"],
            "text1_cached": result1["cached"],
            "text2_cached": result2["cached"]
        }
    
    def find_most_similar(self, query: str, documents: List[str], top_k: int = 5) -> List[Dict[str, Any]]:
        """Find most similar documents to a query"""
        # Get query embedding
        query_result = self.get_embedding(query)
        if query_result.get("error"):
            return [{"error": f"Failed to get query embedding: {query_result['error']}"}]
        
        query_embedding = np.array(query_result["embedding"])
        
        # Get document embeddings
        results = []
        for i, doc in enumerate(documents):
            doc_result = self.get_embedding(doc)
            if doc_result.get("error"):
                continue
            
            doc_embedding = np.array(doc_result["embedding"])
            
            # Calculate similarity
            similarity = cosine_similarity(
                query_embedding.reshape(1, -1),
                doc_embedding.reshape(1, -1)
            )[0][0]
            
            results.append({
                "document": doc,
                "similarity": float(similarity),
                "index": i,
                "tokens_used": doc_result["tokens_used"],
                "cost": doc_result["cost"],
                "cached": doc_result["cached"]
            })
        
        # Sort by similarity and return top k
        results.sort(key=lambda x: x["similarity"], reverse=True)
        return results[:top_k]
    
    def cluster_texts(self, texts: List[str], n_clusters: int = 3) -> Dict[str, Any]:
        """Cluster texts based on embeddings"""
        from sklearn.cluster import KMeans
        
        # Get embeddings for all texts
        embeddings = []
        valid_texts = []
        
        for text in texts:
            result = self.get_embedding(text)
            if not result.get("error"):
                embeddings.append(result["embedding"])
                valid_texts.append(text)
        
        if len(embeddings) < n_clusters:
            return {
                "error": f"Need at least {n_clusters} valid embeddings, got {len(embeddings)}"
            }
        
        # Perform clustering
        embeddings_array = np.array(embeddings)
        kmeans = KMeans(n_clusters=n_clusters, random_state=42)
        cluster_labels = kmeans.fit_predict(embeddings_array)
        
        # Organize results by cluster
        clusters = {}
        for i, (text, label) in enumerate(zip(valid_texts, cluster_labels)):
            if label not in clusters:
                clusters[label] = []
            clusters[label].append({
                "text": text,
                "index": i
            })
        
        return {
            "clusters": clusters,
            "n_clusters": n_clusters,
            "n_texts": len(valid_texts),
            "cluster_centers": kmeans.cluster_centers_.tolist()
        }
    
    def get_stats(self) -> Dict[str, Any]:
        """Get usage statistics"""
        return {
            "total_requests": self.request_count,
            "total_tokens": self.total_tokens,
            "total_cost": self.total_cost,
            "cached_embeddings": len(self.cache),
            "model": self.model
        }

def similarity_example():
    """Example of calculating text similarity"""
    print("Text Similarity Example")
    print("-" * 30)
    
    try:
        client = OpenAIEmbeddingsClient()
    except Exception as e:
        print(f"Error: {e}")
        return
    
    # Example texts
    texts = [
        "The cat sat on the mat.",
        "A feline was resting on the rug.",
        "The dog ran in the park.",
        "Python is a programming language.",
        "JavaScript is used for web development."
    ]
    
    # Compare first text with all others
    query = texts[0]
    print(f"Query: {query}")
    print("\nSimilarities:")
    
    for i, text in enumerate(texts[1:], 1):
        result = client.calculate_similarity(query, text)
        if result.get("error"):
            print(f"{i}. Error: {result['error']}")
        else:
            print(f"{i}. Similarity: {result['similarity']:.4f} - {text}")
            print(f"   Tokens: {result['tokens_used']}, Cost: ${result['cost']:.6f}")

def semantic_search_example():
    """Example of semantic search"""
    print("Semantic Search Example")
    print("-" * 30)
    
    try:
        client = OpenAIEmbeddingsClient()
    except Exception as e:
        print(f"Error: {e}")
        return
    
    # Document collection
    documents = [
        "Python is a high-level programming language.",
        "Machine learning is a subset of artificial intelligence.",
        "The cat sat on the mat.",
        "Natural language processing helps computers understand human language.",
        "Deep learning uses neural networks with multiple layers.",
        "The weather is sunny today.",
        "Reinforcement learning is learning through trial and error.",
        "JavaScript is popular for web development.",
        "Computer vision enables machines to interpret visual information.",
        "The dog ran quickly through the park."
    ]
    
    # Search queries
    queries = [
        "artificial intelligence and machine learning",
        "programming languages",
        "animals and pets"
    ]
    
    for query in queries:
        print(f"\nQuery: {query}")
        print("Top matches:")
        
        results = client.find_most_similar(query, documents, top_k=3)
        
        for i, result in enumerate(results, 1):
            if result.get("error"):
                print(f"{i}. Error: {result['error']}")
            else:
                print(f"{i}. Similarity: {result['similarity']:.4f}")
                print(f"   Document: {result['document']}")
                print(f"   Cached: {result['cached']}")

def clustering_example():
    """Example of text clustering"""
    print("Text Clustering Example")
    print("-" * 30)
    
    try:
        client = OpenAIEmbeddingsClient()
    except Exception as e:
        print(f"Error: {e}")
        return
    
    # Mix of texts from different topics
    texts = [
        # Programming
        "Python is a versatile programming language.",
        "JavaScript is essential for web development.",
        "Machine learning algorithms require data.",
        
        # Animals
        "The cat climbed the tree.",
        "Dogs are loyal companions.",
        "Birds can fly in the sky.",
        
        # Food
        "Pizza is a popular Italian dish.",
        "Sushi is a Japanese cuisine.",
        "Burgers are American fast food.",
        
        # Weather
        "It's raining heavily today.",
        "The sun is shining brightly.",
        "Snow is falling softly."
    ]
    
    result = client.cluster_texts(texts, n_clusters=4)
    
    if result.get("error"):
        print(f"Error: {result['error']}")
        return
    
    print(f"Clustered {result['n_texts']} texts into {result['n_clusters']} clusters:")
    
    for cluster_id, cluster_texts in result["clusters"].items():
        print(f"\nCluster {cluster_id}:")
        for item in cluster_texts:
            print(f"  - {item['text']}")

def main():
    """Main function with options"""
    if len(sys.argv) > 1:
        if sys.argv[1] == "similarity":
            similarity_example()
        elif sys.argv[1] == "search":
            semantic_search_example()
        elif sys.argv[1] == "clustering":
            clustering_example()
        else:
            print("Usage: python example-embeddings.py [similarity|search|clustering]")
            print("  similarity - Text similarity comparison")
            print("  search - Semantic search example")
            print("  clustering - Text clustering example")
    else:
        print("Running all examples:")
        print("=" * 50)
        similarity_example()
        print("\n" + "=" * 50)
        semantic_search_example()
        print("\n" + "=" * 50)
        clustering_example()

if __name__ == "__main__":
    main()