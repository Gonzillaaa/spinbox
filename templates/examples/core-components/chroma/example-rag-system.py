#!/usr/bin/env python3
"""
Chroma RAG System Example (Python)

This example demonstrates building a complete RAG (Retrieval-Augmented Generation)
system using Chroma for vector storage and retrieval.
"""

import os
import sys
import uuid
import json
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime
from dataclasses import dataclass, asdict
import chromadb
from chromadb.config import Settings
from chromadb.utils import embedding_functions
from dotenv import load_dotenv
import requests

# Load environment variables
load_dotenv()

@dataclass
class Document:
    """Document data model."""
    id: str
    content: str
    title: str
    source: str
    metadata: Dict[str, Any]
    created_at: datetime = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()

@dataclass
class RAGResult:
    """RAG system result."""
    query: str
    answer: str
    sources: List[Dict[str, Any]]
    context_used: List[str]
    confidence: float

class ChromaRAGSystem:
    """RAG system using Chroma for vector storage and retrieval."""
    
    def __init__(self, 
                 persist_directory: str = "./chroma_rag_data",
                 collection_name: str = "rag_knowledge_base",
                 embedding_model: str = "sentence-transformers",
                 llm_provider: str = "openai"):
        """Initialize the RAG system."""
        
        self.persist_directory = persist_directory
        self.collection_name = collection_name
        self.llm_provider = llm_provider
        
        # Initialize Chroma client
        self.client = chromadb.PersistentClient(
            path=persist_directory,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # Set up embedding function
        if embedding_model == "sentence-transformers":
            self.embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name="all-MiniLM-L6-v2"
            )
        elif embedding_model == "openai":
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
            self.embedding_function = embedding_functions.DefaultEmbeddingFunction()
        
        # Initialize collection
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            embedding_function=self.embedding_function,
            metadata={"description": "RAG knowledge base collection"}
        )
        
        # Initialize LLM client
        self.llm_client = self._init_llm_client()
        
        print(f"✅ RAG system initialized")
        print(f"📁 Persist directory: {persist_directory}")
        print(f"🔮 Collection: {collection_name}")
        print(f"🧠 Embedding model: {embedding_model}")
        print(f"🤖 LLM provider: {llm_provider}")
    
    def _init_llm_client(self):
        """Initialize LLM client based on provider."""
        if self.llm_provider == "openai":
            import openai
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                print("⚠️ OpenAI API key not found, using mock LLM")
                return None
            return openai.OpenAI(api_key=api_key)
        else:
            print("⚠️ Using mock LLM (no actual generation)")
            return None
    
    def add_document(self, document: Document) -> bool:
        """Add a document to the knowledge base."""
        try:
            # Prepare document data
            doc_id = document.id
            content = document.content
            metadata = {
                "title": document.title,
                "source": document.source,
                "created_at": document.created_at.isoformat(),
                **document.metadata
            }
            
            # Add to collection
            self.collection.add(
                documents=[content],
                metadatas=[metadata],
                ids=[doc_id]
            )
            
            print(f"✅ Added document: {document.title}")
            return True
            
        except Exception as e:
            print(f"❌ Error adding document: {e}")
            return False
    
    def add_documents_batch(self, documents: List[Document]) -> int:
        """Add multiple documents in batch."""
        try:
            doc_ids = [doc.id for doc in documents]
            contents = [doc.content for doc in documents]
            metadatas = [
                {
                    "title": doc.title,
                    "source": doc.source,
                    "created_at": doc.created_at.isoformat(),
                    **doc.metadata
                }
                for doc in documents
            ]
            
            # Add to collection
            self.collection.add(
                documents=contents,
                metadatas=metadatas,
                ids=doc_ids
            )
            
            print(f"✅ Added {len(documents)} documents in batch")
            return len(documents)
            
        except Exception as e:
            print(f"❌ Error adding documents batch: {e}")
            return 0
    
    def search_documents(self, 
                        query: str, 
                        n_results: int = 5,
                        where: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """Search for relevant documents."""
        try:
            # Query the collection
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results,
                where=where
            )
            
            # Format results
            formatted_results = []
            if results['documents'][0]:
                for i, (doc, metadata, distance) in enumerate(zip(
                    results['documents'][0],
                    results['metadatas'][0],
                    results['distances'][0]
                )):
                    formatted_results.append({
                        "id": results['ids'][0][i],
                        "content": doc,
                        "metadata": metadata,
                        "distance": distance,
                        "relevance_score": 1 - distance  # Convert distance to similarity
                    })
            
            return formatted_results
            
        except Exception as e:
            print(f"❌ Error searching documents: {e}")
            return []
    
    def generate_answer(self, query: str, context: List[str]) -> str:
        """Generate answer using LLM."""
        if not self.llm_client:
            # Mock response for demonstration
            return f"Based on the provided context, here's what I can tell you about '{query}': {context[0][:100]}... (This is a mock response - configure OpenAI API key for real generation)"
        
        try:
            # Prepare context
            context_text = "\n\n".join(context)
            
            # Create prompt
            prompt = f"""Based on the following context, please answer the question. If the context doesn't contain enough information to answer the question, say so.

Context:
{context_text}

Question: {query}

Answer:"""
            
            # Generate response
            response = self.llm_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful assistant that answers questions based on provided context."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=500,
                temperature=0.3
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            print(f"❌ Error generating answer: {e}")
            return f"Error generating answer: {str(e)}"
    
    def query_rag(self, 
                  query: str, 
                  n_results: int = 5,
                  min_relevance: float = 0.3) -> RAGResult:
        """Perform RAG query (retrieve + generate)."""
        try:
            # Step 1: Retrieve relevant documents
            search_results = self.search_documents(query, n_results)
            
            # Filter by relevance
            relevant_docs = [
                doc for doc in search_results 
                if doc['relevance_score'] >= min_relevance
            ]
            
            if not relevant_docs:
                return RAGResult(
                    query=query,
                    answer="I don't have enough relevant information to answer this question.",
                    sources=[],
                    context_used=[],
                    confidence=0.0
                )
            
            # Step 2: Prepare context
            context = [doc['content'] for doc in relevant_docs]
            
            # Step 3: Generate answer
            answer = self.generate_answer(query, context)
            
            # Step 4: Prepare sources
            sources = [
                {
                    "title": doc['metadata'].get('title', 'Unknown'),
                    "source": doc['metadata'].get('source', 'Unknown'),
                    "relevance_score": doc['relevance_score'],
                    "excerpt": doc['content'][:200] + "..." if len(doc['content']) > 200 else doc['content']
                }
                for doc in relevant_docs
            ]
            
            # Calculate confidence based on relevance scores
            confidence = sum(doc['relevance_score'] for doc in relevant_docs) / len(relevant_docs)
            
            return RAGResult(
                query=query,
                answer=answer,
                sources=sources,
                context_used=context,
                confidence=confidence
            )
            
        except Exception as e:
            print(f"❌ Error in RAG query: {e}")
            return RAGResult(
                query=query,
                answer=f"Error processing query: {str(e)}",
                sources=[],
                context_used=[],
                confidence=0.0
            )
    
    def get_knowledge_base_stats(self) -> Dict[str, Any]:
        """Get statistics about the knowledge base."""
        try:
            count = self.collection.count()
            
            # Get sample documents to analyze
            sample_docs = self.collection.get(limit=min(100, count))
            
            # Analyze sources
            sources = {}
            for metadata in sample_docs['metadatas']:
                source = metadata.get('source', 'Unknown')
                sources[source] = sources.get(source, 0) + 1
            
            return {
                "total_documents": count,
                "sources": sources,
                "collection_name": self.collection_name,
                "embedding_model": type(self.embedding_function).__name__
            }
            
        except Exception as e:
            print(f"❌ Error getting stats: {e}")
            return {}
    
    def reset_knowledge_base(self) -> bool:
        """Reset the knowledge base."""
        try:
            self.client.delete_collection(self.collection_name)
            self.collection = self.client.get_or_create_collection(
                name=self.collection_name,
                embedding_function=self.embedding_function,
                metadata={"description": "RAG knowledge base collection"}
            )
            print("✅ Knowledge base reset")
            return True
            
        except Exception as e:
            print(f"❌ Error resetting knowledge base: {e}")
            return False

class RAGDemo:
    """RAG system demonstration."""
    
    def __init__(self):
        """Initialize the demo."""
        self.rag_system = ChromaRAGSystem()
    
    def seed_knowledge_base(self):
        """Seed the knowledge base with sample documents."""
        print("\n🌱 Seeding knowledge base with sample documents...")
        
        sample_documents = [
            Document(
                id="doc_python_intro",
                content="Python is a high-level, interpreted programming language with dynamic semantics. Its high-level built in data structures, combined with dynamic typing and dynamic binding, make it very attractive for Rapid Application Development, as well as for use as a scripting or glue language to connect existing components together. Python's simple, easy to learn syntax emphasizes readability and therefore reduces the cost of program maintenance.",
                title="Introduction to Python",
                source="Python Documentation",
                metadata={"category": "programming", "difficulty": "beginner", "language": "python"}
            ),
            Document(
                id="doc_ml_basics",
                content="Machine Learning is a subset of artificial intelligence (AI) that provides systems the ability to automatically learn and improve from experience without being explicitly programmed. Machine learning focuses on the development of computer programs that can access data and use it to learn for themselves. The process of learning begins with observations or data, such as examples, direct experience, or instruction, in order to look for patterns in data and make better decisions in the future based on the examples that we provide.",
                title="Machine Learning Basics",
                source="AI Handbook",
                metadata={"category": "ai", "difficulty": "intermediate", "subtopic": "machine_learning"}
            ),
            Document(
                id="doc_web_dev",
                content="Web development is the work involved in developing a Web site for the Internet or an intranet. Web development can range from developing a simple single static page of plain text to complex Web-based Internet applications, electronic businesses, and social network services. A more comprehensive list of tasks to which Web development commonly refers, may include Web engineering, Web design, Web content development, client liaison, client-side/server-side scripting, Web server and network security configuration, and e-commerce development.",
                title="Web Development Overview",
                source="Web Development Guide",
                metadata={"category": "web", "difficulty": "beginner", "subtopic": "overview"}
            ),
            Document(
                id="doc_data_science",
                content="Data science is an interdisciplinary field that uses scientific methods, processes, algorithms and systems to extract knowledge and insights from structured and unstructured data. Data science is related to data mining, machine learning and big data. Data science is a concept to unify statistics, data analysis, machine learning, and their related methods in order to understand and analyze actual phenomena with data. It employs techniques and theories drawn from many fields within the context of mathematics, statistics, computer science, and information science.",
                title="Data Science Introduction",
                source="Data Science Handbook",
                metadata={"category": "data", "difficulty": "intermediate", "subtopic": "overview"}
            ),
            Document(
                id="doc_api_design",
                content="API design is the process of developing Application Programming Interfaces (APIs) that expose data and application functionality for use by developers and users. Good API design is important for system integration and development efficiency. REST APIs are a popular architectural style for designing networked applications. They rely on a stateless, client-server, cacheable communications protocol. RESTful APIs use HTTP methods like GET, POST, PUT, and DELETE to perform operations on resources identified by URLs.",
                title="API Design Best Practices",
                source="Software Architecture Guide",
                metadata={"category": "software", "difficulty": "intermediate", "subtopic": "api_design"}
            ),
            Document(
                id="doc_database_design",
                content="Database design is the organization of data according to a database model. The designer determines what data must be stored and how the data elements interrelate. With this information, they can begin to fit the data to the database model. Database design involves classifying data and identifying interrelationships. This theoretical representation of the data is called an ontology or conceptual schema. The conceptual schema is then translated into a logical schema which documents entities, attributes, and relationships.",
                title="Database Design Principles",
                source="Database Systems Manual",
                metadata={"category": "database", "difficulty": "advanced", "subtopic": "design"}
            ),
            Document(
                id="doc_cloud_computing",
                content="Cloud computing is the delivery of computing services including servers, storage, databases, networking, software, analytics, and intelligence over the Internet to offer faster innovation, flexible resources, and economies of scale. You typically pay only for cloud services you use, helping lower your operating costs, run your infrastructure more efficiently and scale as your business needs change. Cloud computing eliminates the capital expense of buying hardware and software and setting up and running on-site datacenters.",
                title="Cloud Computing Overview",
                source="Cloud Technology Guide",
                metadata={"category": "cloud", "difficulty": "intermediate", "subtopic": "overview"}
            ),
            Document(
                id="doc_cybersecurity",
                content="Cybersecurity is the practice of protecting systems, networks, and programs from digital attacks. These cyberattacks are usually aimed at accessing, changing, or destroying sensitive information; extorting money from users; or interrupting normal business processes. Implementing effective cybersecurity measures is particularly challenging today because there are more devices than people, and attackers are becoming more innovative. A successful cybersecurity approach has multiple layers of protection spread across the computers, networks, programs, or data that one intends to keep safe.",
                title="Cybersecurity Fundamentals",
                source="Security Handbook",
                metadata={"category": "security", "difficulty": "intermediate", "subtopic": "fundamentals"}
            )
        ]
        
        # Add documents to knowledge base
        added_count = self.rag_system.add_documents_batch(sample_documents)
        
        if added_count > 0:
            print(f"✅ Added {added_count} documents to knowledge base")
            
            # Show knowledge base stats
            stats = self.rag_system.get_knowledge_base_stats()
            print(f"📊 Knowledge base stats:")
            print(f"  Total documents: {stats['total_documents']}")
            print(f"  Sources: {', '.join(stats['sources'].keys())}")
        
        return added_count > 0
    
    def demo_rag_queries(self):
        """Demonstrate RAG queries."""
        print("\n🤖 RAG Query Demonstrations")
        print("-" * 40)
        
        # Sample queries
        queries = [
            "What is Python programming?",
            "How does machine learning work?",
            "What are the best practices for API design?",
            "What is cloud computing?",
            "How can I protect my system from cyber attacks?"
        ]
        
        for query in queries:
            print(f"\n🔍 Query: {query}")
            print("=" * 50)
            
            # Perform RAG query
            result = self.rag_system.query_rag(query, n_results=3)
            
            print(f"💬 Answer: {result.answer}")
            print(f"🎯 Confidence: {result.confidence:.2f}")
            
            if result.sources:
                print(f"📚 Sources ({len(result.sources)}):")
                for i, source in enumerate(result.sources, 1):
                    print(f"  {i}. {source['title']} (relevance: {source['relevance_score']:.2f})")
                    print(f"     {source['excerpt']}")
                    print()
    
    def demo_filtered_search(self):
        """Demonstrate filtered search."""
        print("\n🎯 Filtered Search Demonstration")
        print("-" * 40)
        
        # Search by category
        query = "programming concepts"
        category_filter = {"category": "programming"}
        
        print(f"🔍 Query: {query}")
        print(f"📂 Filter: {category_filter}")
        
        results = self.rag_system.search_documents(
            query,
            n_results=3,
            where=category_filter
        )
        
        if results:
            print(f"✅ Found {len(results)} results:")
            for i, result in enumerate(results, 1):
                print(f"  {i}. {result['metadata']['title']}")
                print(f"     Relevance: {result['relevance_score']:.2f}")
                print(f"     Content: {result['content'][:100]}...")
                print()
        else:
            print("❌ No results found")
    
    def cleanup(self):
        """Clean up demo data."""
        print("\n🧹 Cleaning up demo data...")
        success = self.rag_system.reset_knowledge_base()
        if success:
            print("✅ Knowledge base reset")

def main():
    """Main function demonstrating Chroma RAG system."""
    print("🔮 Chroma RAG System Example (Python)")
    print("=" * 50)
    
    try:
        # Initialize demo
        demo = RAGDemo()
        
        # Seed knowledge base
        if not demo.seed_knowledge_base():
            print("❌ Failed to seed knowledge base")
            return
        
        # Run demonstrations
        demo.demo_rag_queries()
        demo.demo_filtered_search()
        
        # Interactive mode
        print("\n" + "=" * 50)
        print("🎯 Interactive RAG System")
        print("Commands:")
        print("  'ask <question>' - Ask a question")
        print("  'search <query>' - Search documents")
        print("  'filter <category> <query>' - Filtered search")
        print("  'stats' - Show knowledge base statistics")
        print("  'add <title> | <content>' - Add a document")
        print("  'reset' - Reset knowledge base")
        print("  'quit' - Exit")
        print("-" * 50)
        
        while True:
            user_input = input("\n🤖 RAG> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'stats':
                stats = demo.rag_system.get_knowledge_base_stats()
                print("📊 Knowledge Base Statistics:")
                print(f"  Total documents: {stats['total_documents']}")
                print(f"  Sources: {', '.join(stats['sources'].keys())}")
                print(f"  Collection: {stats['collection_name']}")
            elif user_input.startswith('ask '):
                question = user_input[4:]
                print(f"🤔 Thinking about: {question}")
                result = demo.rag_system.query_rag(question)
                
                print(f"\n💬 Answer: {result.answer}")
                print(f"🎯 Confidence: {result.confidence:.2f}")
                
                if result.sources:
                    print(f"📚 Sources:")
                    for i, source in enumerate(result.sources, 1):
                        print(f"  {i}. {source['title']} (relevance: {source['relevance_score']:.2f})")
            elif user_input.startswith('search '):
                query = user_input[7:]
                results = demo.rag_system.search_documents(query, n_results=3)
                
                if results:
                    print(f"🔍 Search results for '{query}':")
                    for i, result in enumerate(results, 1):
                        print(f"  {i}. {result['metadata']['title']}")
                        print(f"     Relevance: {result['relevance_score']:.2f}")
                        print(f"     {result['content'][:100]}...")
                else:
                    print("❌ No results found")
            elif user_input.startswith('filter '):
                parts = user_input[7:].split(' ', 1)
                if len(parts) == 2:
                    category, query = parts
                    results = demo.rag_system.search_documents(
                        query,
                        n_results=3,
                        where={"category": category}
                    )
                    
                    if results:
                        print(f"🎯 Filtered results for '{query}' in '{category}':")
                        for i, result in enumerate(results, 1):
                            print(f"  {i}. {result['metadata']['title']}")
                            print(f"     Relevance: {result['relevance_score']:.2f}")
                    else:
                        print("❌ No results found")
                else:
                    print("Usage: filter <category> <query>")
            elif user_input.startswith('add '):
                doc_info = user_input[4:]
                if ' | ' in doc_info:
                    title, content = doc_info.split(' | ', 1)
                    doc = Document(
                        id=f"user_doc_{uuid.uuid4()}",
                        content=content,
                        title=title,
                        source="User Input",
                        metadata={"category": "user_added"}
                    )
                    
                    if demo.rag_system.add_document(doc):
                        print("✅ Document added successfully")
                    else:
                        print("❌ Failed to add document")
                else:
                    print("Usage: add <title> | <content>")
            elif user_input.lower() == 'reset':
                demo.cleanup()
                print("✅ Knowledge base reset")
            elif user_input:
                print("Unknown command. Type 'quit' to exit.")
        
        # Final cleanup
        if user_input.lower() != 'reset':
            demo.cleanup()
        
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()