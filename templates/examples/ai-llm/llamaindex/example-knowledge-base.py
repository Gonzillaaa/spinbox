#!/usr/bin/env python3
"""
LlamaIndex Knowledge Base Example

This example demonstrates building a comprehensive knowledge base
with persistent storage, multiple data sources, and advanced retrieval.
"""

import os
import sys
import json
from typing import List, Dict, Any, Optional
from llama_index import VectorStoreIndex, SimpleDirectoryReader, Document
from llama_index.llms import OpenAI
from llama_index.embeddings import OpenAIEmbedding
from llama_index.node_parser import SimpleNodeParser
from llama_index.service_context import ServiceContext
from llama_index.storage.storage_context import StorageContext
from llama_index.storage.docstore import SimpleDocumentStore
from llama_index.storage.index_store import SimpleIndexStore
from llama_index.vector_stores import SimpleVectorStore
from llama_index.retrievers import VectorIndexRetriever
from llama_index.postprocessor import SimilarityPostprocessor
from llama_index.query_engine import RetrieverQueryEngine
from llama_index.response_synthesizers import get_response_synthesizer, ResponseMode
from llama_index.indices.postprocessor import MetadataReplacementPostProcessor
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
load_dotenv()

class KnowledgeBaseSystem:
    """Advanced knowledge base system with persistent storage."""
    
    def __init__(self, 
                 documents_path: str = "documents",
                 storage_path: str = "storage"):
        """Initialize the knowledge base system."""
        self.documents_path = documents_path
        self.storage_path = storage_path
        
        # Check for API key
        self.openai_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_key:
            raise ValueError("OPENAI_API_KEY is required")
        
        # Configuration
        self.model = os.getenv("LLAMAINDEX_MODEL", "gpt-3.5-turbo")
        self.temperature = float(os.getenv("LLAMAINDEX_TEMPERATURE", "0.1"))
        self.max_tokens = int(os.getenv("LLAMAINDEX_MAX_TOKENS", "1024"))
        
        # Initialize components
        self.llm = OpenAI(
            api_key=self.openai_key,
            model=self.model,
            temperature=self.temperature,
            max_tokens=self.max_tokens
        )
        
        self.embed_model = OpenAIEmbedding(api_key=self.openai_key)
        
        # Node parser with metadata extraction
        self.node_parser = SimpleNodeParser.from_defaults(
            chunk_size=512,
            chunk_overlap=50,
            include_metadata=True
        )
        
        # Service context
        self.service_context = ServiceContext.from_defaults(
            llm=self.llm,
            embed_model=self.embed_model,
            node_parser=self.node_parser
        )
        
        # Storage components
        self.storage_context = None
        self.index = None
        self.query_engine = None
        
        # Metadata for knowledge base
        self.metadata_path = os.path.join(self.storage_path, "metadata.json")
        self.metadata = {}
    
    def setup_storage(self):
        """Set up persistent storage."""
        try:
            # Create storage directory
            os.makedirs(self.storage_path, exist_ok=True)
            
            # Initialize storage context
            if self._storage_exists():
                print("📦 Loading existing storage...")
                self.storage_context = StorageContext.from_defaults(
                    persist_dir=self.storage_path
                )
            else:
                print("📦 Creating new storage...")
                self.storage_context = StorageContext.from_defaults(
                    docstore=SimpleDocumentStore(),
                    index_store=SimpleIndexStore(),
                    vector_store=SimpleVectorStore()
                )
            
            # Load metadata
            self._load_metadata()
            
        except Exception as e:
            print(f"❌ Error setting up storage: {str(e)}")
            raise
    
    def _storage_exists(self) -> bool:
        """Check if storage already exists."""
        return os.path.exists(os.path.join(self.storage_path, "docstore.json"))
    
    def _load_metadata(self):
        """Load knowledge base metadata."""
        try:
            if os.path.exists(self.metadata_path):
                with open(self.metadata_path, 'r') as f:
                    self.metadata = json.load(f)
            else:
                self.metadata = {
                    "created_at": None,
                    "last_updated": None,
                    "document_count": 0,
                    "categories": [],
                    "version": "1.0"
                }
        except Exception as e:
            print(f"⚠️ Error loading metadata: {str(e)}")
            self.metadata = {}
    
    def _save_metadata(self):
        """Save knowledge base metadata."""
        try:
            with open(self.metadata_path, 'w') as f:
                json.dump(self.metadata, f, indent=2)
        except Exception as e:
            print(f"⚠️ Error saving metadata: {str(e)}")
    
    def load_documents(self) -> List[Document]:
        """Load documents with enhanced metadata."""
        try:
            if not os.path.exists(self.documents_path):
                self._create_sample_documents()
            
            # Load documents with metadata
            documents = SimpleDirectoryReader(
                self.documents_path,
                recursive=True,
                filename_as_id=True
            ).load_data()
            
            # Enhance documents with metadata
            enhanced_documents = []
            for doc in documents:
                # Extract category from file path
                file_path = Path(doc.metadata.get("file_path", ""))
                category = file_path.parent.name if file_path.parent.name != self.documents_path else "general"
                
                # Add enhanced metadata
                doc.metadata.update({
                    "category": category,
                    "file_size": len(doc.text),
                    "word_count": len(doc.text.split()),
                    "source_type": "file"
                })
                
                enhanced_documents.append(doc)
            
            print(f"📁 Loaded {len(enhanced_documents)} documents with metadata")
            return enhanced_documents
            
        except Exception as e:
            print(f"❌ Error loading documents: {str(e)}")
            return []
    
    def _create_sample_documents(self):
        """Create sample documents with categories."""
        os.makedirs(self.documents_path, exist_ok=True)
        
        # Create category directories
        categories = ["ai", "programming", "business"]
        for category in categories:
            os.makedirs(os.path.join(self.documents_path, category), exist_ok=True)
        
        sample_docs = {
            "ai/neural_networks.txt": """
            Neural Networks are computing systems inspired by biological neural networks.
            They consist of interconnected nodes (neurons) that process information.
            
            Key components:
            - Input layer: Receives data
            - Hidden layers: Process information
            - Output layer: Produces results
            - Weights and biases: Learned parameters
            
            Types of neural networks:
            - Feedforward networks
            - Convolutional neural networks (CNNs)
            - Recurrent neural networks (RNNs)
            - Transformer networks
            
            Applications include image recognition, natural language processing,
            and pattern recognition tasks.
            """,
            
            "programming/python_basics.txt": """
            Python is a high-level, interpreted programming language known for its
            simplicity and readability.
            
            Key features:
            - Easy to learn and use
            - Extensive standard library
            - Dynamic typing
            - Object-oriented programming support
            - Large ecosystem of third-party packages
            
            Common use cases:
            - Web development (Django, Flask)
            - Data science (Pandas, NumPy)
            - Machine learning (TensorFlow, PyTorch)
            - Automation and scripting
            - Scientific computing
            
            Python's philosophy: "Simple is better than complex."
            """,
            
            "business/startup_strategy.txt": """
            Startup Strategy involves planning and executing the launch and growth
            of a new business venture.
            
            Key elements:
            - Market research and validation
            - Product-market fit
            - Business model development
            - Funding and investment
            - Team building and scaling
            
            Common strategies:
            - Lean startup methodology
            - MVP (Minimum Viable Product) development
            - Customer development
            - Agile development practices
            - Growth hacking techniques
            
            Success factors:
            - Strong founding team
            - Clear value proposition
            - Scalable business model
            - Adequate funding
            - Market timing
            """,
            
            "ai/llm_frameworks.txt": """
            Large Language Model (LLM) frameworks provide tools and abstractions
            for building applications with language models.
            
            Popular frameworks:
            - LangChain: Comprehensive framework for LLM applications
            - LlamaIndex: Data framework for LLM applications
            - Haystack: End-to-end framework for search and QA
            - Semantic Kernel: Microsoft's framework for AI integration
            
            Key capabilities:
            - Prompt management and optimization
            - Chain of thought reasoning
            - Memory and context management
            - Tool integration and function calling
            - Vector database integration
            
            These frameworks enable developers to build sophisticated AI applications
            without dealing with low-level model complexities.
            """
        }
        
        for file_path, content in sample_docs.items():
            full_path = os.path.join(self.documents_path, file_path)
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content.strip())
        
        print(f"📝 Created {len(sample_docs)} sample documents with categories")
    
    def create_or_load_index(self, documents: List[Document] = None) -> bool:
        """Create new index or load existing one."""
        try:
            if self._storage_exists() and not documents:
                print("📊 Loading existing index...")
                self.index = VectorStoreIndex.from_documents(
                    [],
                    storage_context=self.storage_context,
                    service_context=self.service_context
                )
                # Load from storage
                self.index = VectorStoreIndex.from_documents(
                    [],
                    storage_context=self.storage_context,
                    service_context=self.service_context
                )
                
            else:
                print("📊 Creating new index...")
                if not documents:
                    documents = self.load_documents()
                
                self.index = VectorStoreIndex.from_documents(
                    documents,
                    storage_context=self.storage_context,
                    service_context=self.service_context
                )
                
                # Update metadata
                self.metadata.update({
                    "document_count": len(documents),
                    "categories": list(set(doc.metadata.get("category", "general") for doc in documents)),
                    "last_updated": str(os.path.getmtime(self.documents_path))
                })
                
                self._save_metadata()
                
                # Persist the index
                self.index.storage_context.persist(persist_dir=self.storage_path)
                print("💾 Index saved to storage")
            
            return True
            
        except Exception as e:
            print(f"❌ Error creating/loading index: {str(e)}")
            return False
    
    def create_advanced_query_engine(self):
        """Create advanced query engine with post-processing."""
        try:
            if not self.index:
                print("❌ Index not created")
                return
            
            # Create retriever with higher similarity threshold
            retriever = VectorIndexRetriever(
                index=self.index,
                similarity_top_k=10
            )
            
            # Post-processors for better results
            postprocessors = [
                SimilarityPostprocessor(similarity_cutoff=0.7),
                MetadataReplacementPostProcessor(target_metadata_key="window")
            ]
            
            # Response synthesizer
            response_synthesizer = get_response_synthesizer(
                service_context=self.service_context,
                response_mode=ResponseMode.COMPACT
            )
            
            # Create query engine
            self.query_engine = RetrieverQueryEngine(
                retriever=retriever,
                response_synthesizer=response_synthesizer,
                node_postprocessors=postprocessors
            )
            
            print("✅ Advanced query engine created")
            
        except Exception as e:
            print(f"❌ Error creating query engine: {str(e)}")
    
    def query(self, question: str, category: str = None) -> Dict[str, Any]:
        """Query the knowledge base with optional category filtering."""
        try:
            if not self.query_engine:
                return {"error": "Query engine not initialized"}
            
            # Add category context if specified
            if category:
                question = f"[Category: {category}] {question}"
            
            response = self.query_engine.query(question)
            
            # Extract source information
            sources = []
            if hasattr(response, 'source_nodes'):
                for node in response.source_nodes:
                    sources.append({
                        "file_name": node.metadata.get("file_name", "Unknown"),
                        "category": node.metadata.get("category", "general"),
                        "similarity": getattr(node, 'score', 0.0),
                        "content_preview": node.text[:100] + "..." if len(node.text) > 100 else node.text
                    })
            
            return {
                "question": question,
                "answer": str(response),
                "sources": sources,
                "metadata": self.metadata
            }
            
        except Exception as e:
            return {"error": f"Query failed: {str(e)}"}
    
    def get_knowledge_base_stats(self) -> Dict[str, Any]:
        """Get comprehensive knowledge base statistics."""
        try:
            stats = {
                "metadata": self.metadata,
                "storage_path": self.storage_path,
                "documents_path": self.documents_path,
                "model": self.model
            }
            
            if self.index:
                # Get document count from docstore
                docstore = self.index.docstore
                stats["indexed_documents"] = len(docstore.docs)
                
                # Get category distribution
                categories = {}
                for doc in docstore.docs.values():
                    category = doc.metadata.get("category", "general")
                    categories[category] = categories.get(category, 0) + 1
                
                stats["category_distribution"] = categories
            
            return stats
            
        except Exception as e:
            return {"error": f"Error getting stats: {str(e)}"}
    
    def initialize(self) -> bool:
        """Initialize the complete knowledge base system."""
        print("🔄 Initializing Knowledge Base System...")
        
        try:
            # Setup storage
            self.setup_storage()
            
            # Create or load index
            if not self.create_or_load_index():
                return False
            
            # Create query engine
            self.create_advanced_query_engine()
            
            print("✅ Knowledge Base System initialized successfully")
            return True
            
        except Exception as e:
            print(f"❌ Initialization failed: {str(e)}")
            return False

def main():
    """Main function demonstrating knowledge base system."""
    print("🦙 LlamaIndex Knowledge Base Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set")
        print("Please set your OpenAI API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize system
        kb = KnowledgeBaseSystem()
        
        if not kb.initialize():
            print("❌ Failed to initialize knowledge base")
            sys.exit(1)
        
        # Show knowledge base statistics
        stats = kb.get_knowledge_base_stats()
        if "error" in stats:
            print(f"❌ Error getting stats: {stats['error']}")
        else:
            print("\n📊 Knowledge Base Statistics:")
            print(f"  Documents: {stats['metadata'].get('document_count', 0)}")
            print(f"  Categories: {', '.join(stats['metadata'].get('categories', []))}")
            print(f"  Storage: {stats['storage_path']}")
            if "category_distribution" in stats:
                print("  Category Distribution:")
                for category, count in stats["category_distribution"].items():
                    print(f"    {category}: {count} documents")
        
        print("\n" + "-" * 50)
        print("🤖 Knowledge Base Ready! Ask questions across categories.")
        print("Commands:")
        print("  'category:<name> <question>' - Query specific category")
        print("  'stats' - Show knowledge base statistics")
        print("  'quit' - Exit")
        print("Example queries:")
        print("  - 'What are neural networks?'")
        print("  - 'category:programming What is Python?'")
        print("  - 'How do startups develop strategy?'")
        print("-" * 50)
        
        while True:
            # Get user input
            user_input = input("\n🧑 Query: ").strip()
            
            # Handle special commands
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'stats':
                stats = kb.get_knowledge_base_stats()
                if "error" in stats:
                    print(f"❌ Error: {stats['error']}")
                else:
                    print("\n📊 Knowledge Base Statistics:")
                    for key, value in stats.items():
                        if key != "error":
                            print(f"  {key}: {value}")
                continue
            elif not user_input:
                continue
            
            # Parse category filter
            category = None
            question = user_input
            if user_input.startswith('category:'):
                parts = user_input.split(' ', 1)
                if len(parts) == 2:
                    category = parts[0].replace('category:', '')
                    question = parts[1]
            
            # Process query
            result = kb.query(question, category)
            
            if "error" in result:
                print(f"❌ Error: {result['error']}")
            else:
                print(f"\n🤖 Answer: {result['answer']}")
                
                if result['sources']:
                    print(f"\n📚 Sources ({len(result['sources'])}):")
                    for i, source in enumerate(result['sources'], 1):
                        print(f"  {i}. {source['file_name']} ({source['category']})")
                        if source['similarity'] > 0:
                            print(f"     Similarity: {source['similarity']:.2f}")
                        print(f"     Preview: {source['content_preview']}")
            
    except KeyboardInterrupt:
        print("\n\n👋 Knowledge base interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()