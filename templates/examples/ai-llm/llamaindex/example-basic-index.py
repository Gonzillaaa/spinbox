#!/usr/bin/env python3
"""
LlamaIndex Basic Indexing Example

This example demonstrates basic document indexing and querying
using LlamaIndex with vector embeddings.
"""

import os
import sys
from typing import List, Dict, Any, Optional
from llama_index import VectorStoreIndex, SimpleDirectoryReader, Document
from llama_index.llms import OpenAI
from llama_index.embeddings import OpenAIEmbedding
from llama_index.node_parser import SimpleNodeParser
from llama_index.service_context import ServiceContext
from llama_index.storage.storage_context import StorageContext
from llama_index.vector_stores import SimpleVectorStore
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class BasicIndexDemo:
    """Basic LlamaIndex functionality demonstration."""
    
    def __init__(self, documents_path: str = "documents"):
        """Initialize the basic index demo."""
        self.documents_path = documents_path
        
        # Check for API key
        self.openai_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_key:
            raise ValueError("OPENAI_API_KEY is required")
        
        # Configuration
        self.model = os.getenv("LLAMAINDEX_MODEL", "gpt-3.5-turbo")
        self.temperature = float(os.getenv("LLAMAINDEX_TEMPERATURE", "0.1"))
        self.max_tokens = int(os.getenv("LLAMAINDEX_MAX_TOKENS", "1024"))
        self.chunk_size = int(os.getenv("LLAMAINDEX_CHUNK_SIZE", "1024"))
        self.chunk_overlap = int(os.getenv("LLAMAINDEX_CHUNK_OVERLAP", "200"))
        
        # Initialize components
        self.llm = OpenAI(
            api_key=self.openai_key,
            model=self.model,
            temperature=self.temperature,
            max_tokens=self.max_tokens
        )
        
        self.embed_model = OpenAIEmbedding(api_key=self.openai_key)
        
        # Node parser for chunking
        self.node_parser = SimpleNodeParser.from_defaults(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap
        )
        
        # Service context
        self.service_context = ServiceContext.from_defaults(
            llm=self.llm,
            embed_model=self.embed_model,
            node_parser=self.node_parser
        )
        
        # Initialize storage
        self.storage_context = StorageContext.from_defaults(
            vector_store=SimpleVectorStore()
        )
        
        self.index = None
        self.query_engine = None
    
    def load_documents(self) -> List[Document]:
        """Load documents from the specified directory."""
        try:
            if not os.path.exists(self.documents_path):
                # Create sample documents if directory doesn't exist
                self._create_sample_documents()
            
            # Load documents
            documents = SimpleDirectoryReader(self.documents_path).load_data()
            print(f"📁 Loaded {len(documents)} documents")
            
            return documents
            
        except Exception as e:
            print(f"❌ Error loading documents: {str(e)}")
            return []
    
    def _create_sample_documents(self):
        """Create sample documents for demonstration."""
        os.makedirs(self.documents_path, exist_ok=True)
        
        sample_docs = {
            "artificial_intelligence.txt": """
            Artificial Intelligence (AI) is a branch of computer science that aims to create 
            intelligent machines that can perform tasks that typically require human intelligence.
            
            AI encompasses various subfields including:
            - Machine Learning: Algorithms that improve through experience
            - Natural Language Processing: Understanding and generating human language
            - Computer Vision: Interpreting and analyzing visual information
            - Robotics: Creating intelligent physical systems
            - Expert Systems: Knowledge-based decision making systems
            
            Modern AI applications include virtual assistants, recommendation systems,
            autonomous vehicles, and medical diagnosis systems.
            """,
            
            "machine_learning.txt": """
            Machine Learning is a subset of artificial intelligence that focuses on
            algorithms that can learn and make decisions from data without being explicitly programmed.
            
            Types of Machine Learning:
            1. Supervised Learning: Learning from labeled examples
            2. Unsupervised Learning: Finding patterns in unlabeled data
            3. Reinforcement Learning: Learning through interaction and feedback
            
            Popular algorithms include:
            - Linear Regression and Logistic Regression
            - Decision Trees and Random Forests
            - Neural Networks and Deep Learning
            - Support Vector Machines
            - K-Means Clustering
            
            Applications include image recognition, natural language processing,
            recommendation systems, and predictive analytics.
            """,
            
            "llamaindex_overview.txt": """
            LlamaIndex is a data framework for building LLM applications with private or domain-specific data.
            It provides tools for ingesting, indexing, and querying your data using large language models.
            
            Key features of LlamaIndex:
            - Data Connectors: Ingest data from various sources
            - Data Indexes: Structure data for efficient retrieval
            - Query Engines: Natural language interface to your data
            - Chat Engines: Conversational interfaces
            - Agents: LLM-powered tools for complex tasks
            
            LlamaIndex supports various data sources including:
            - Documents (PDF, Word, Text)
            - APIs and databases
            - Web pages and structured data
            - Vector databases for storage
            
            It's particularly useful for building RAG (Retrieval-Augmented Generation) systems
            that combine the power of LLMs with your private data.
            """
        }
        
        for filename, content in sample_docs.items():
            filepath = os.path.join(self.documents_path, filename)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content.strip())
        
        print(f"📝 Created {len(sample_docs)} sample documents in {self.documents_path}/")
    
    def create_index(self, documents: List[Document]) -> bool:
        """Create the vector index from documents."""
        try:
            print("🔄 Creating vector index...")
            
            # Create index
            self.index = VectorStoreIndex.from_documents(
                documents,
                service_context=self.service_context,
                storage_context=self.storage_context
            )
            
            # Create query engine
            self.query_engine = self.index.as_query_engine(
                response_mode="tree_summarize",
                verbose=True
            )
            
            print("✅ Index created successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error creating index: {str(e)}")
            return False
    
    def query(self, question: str) -> Dict[str, Any]:
        """Query the index."""
        try:
            if not self.query_engine:
                return {"error": "Query engine not initialized"}
            
            print(f"🔍 Querying: {question}")
            response = self.query_engine.query(question)
            
            return {
                "question": question,
                "answer": str(response),
                "source_nodes": len(response.source_nodes) if hasattr(response, 'source_nodes') else 0
            }
            
        except Exception as e:
            return {"error": f"Query failed: {str(e)}"}
    
    def get_index_stats(self) -> Dict[str, Any]:
        """Get statistics about the index."""
        try:
            if not self.index:
                return {"error": "Index not created"}
            
            # Get node count
            nodes = self.index.docstore.docs
            node_count = len(nodes)
            
            # Get document sources
            sources = set()
            for node in nodes.values():
                if hasattr(node, 'metadata') and 'file_name' in node.metadata:
                    sources.add(node.metadata['file_name'])
            
            return {
                "node_count": node_count,
                "document_sources": list(sources),
                "model": self.model,
                "chunk_size": self.chunk_size,
                "chunk_overlap": self.chunk_overlap
            }
            
        except Exception as e:
            return {"error": f"Error getting stats: {str(e)}"}
    
    def initialize(self) -> bool:
        """Initialize the complete system."""
        print("🔄 Initializing LlamaIndex system...")
        
        # Load documents
        documents = self.load_documents()
        if not documents:
            print("❌ No documents loaded")
            return False
        
        # Create index
        if not self.create_index(documents):
            return False
        
        print("✅ LlamaIndex system initialized successfully")
        return True

def main():
    """Main function demonstrating basic LlamaIndex usage."""
    print("🦙 LlamaIndex Basic Index Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set")
        print("Please set your OpenAI API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize system
        demo = BasicIndexDemo()
        
        if not demo.initialize():
            print("❌ Failed to initialize system")
            sys.exit(1)
        
        # Show index statistics
        stats = demo.get_index_stats()
        if "error" in stats:
            print(f"❌ Error getting stats: {stats['error']}")
        else:
            print("\n📊 Index Statistics:")
            print(f"  Nodes: {stats['node_count']}")
            print(f"  Documents: {', '.join(stats['document_sources'])}")
            print(f"  Model: {stats['model']}")
            print(f"  Chunk Size: {stats['chunk_size']}")
        
        print("\n" + "-" * 50)
        print("🤖 Query Engine Ready! Ask questions about the documents.")
        print("Type 'quit' to exit, 'stats' for index statistics")
        print("Example queries:")
        print("  - 'What is artificial intelligence?'")
        print("  - 'What are the types of machine learning?'")
        print("  - 'How does LlamaIndex work?'")
        print("-" * 50)
        
        while True:
            # Get user input
            user_input = input("\n🧑 Question: ").strip()
            
            # Handle special commands
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'stats':
                stats = demo.get_index_stats()
                if "error" in stats:
                    print(f"❌ Error: {stats['error']}")
                else:
                    print("\n📊 Index Statistics:")
                    for key, value in stats.items():
                        print(f"  {key}: {value}")
                continue
            elif not user_input:
                continue
            
            # Process query
            result = demo.query(user_input)
            
            if "error" in result:
                print(f"❌ Error: {result['error']}")
            else:
                print(f"\n🤖 Answer: {result['answer']}")
                if result['source_nodes'] > 0:
                    print(f"📚 Sources: {result['source_nodes']} relevant chunks")
            
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()