#!/usr/bin/env python3
"""
LlamaIndex Query Engine Example

This example demonstrates advanced query engine features
including different response modes, custom prompts, and query optimization.
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
from llama_index.query_engine import RetrieverQueryEngine
from llama_index.retrievers import VectorIndexRetriever
from llama_index.response_synthesizers import ResponseMode, get_response_synthesizer
from llama_index.prompts import PromptTemplate
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class QueryEngineDemo:
    """Advanced query engine demonstration."""
    
    def __init__(self, documents_path: str = "documents"):
        """Initialize the query engine demo."""
        self.documents_path = documents_path
        
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
        
        # Service context
        self.service_context = ServiceContext.from_defaults(
            llm=self.llm,
            embed_model=self.embed_model
        )
        
        self.index = None
        self.query_engines = {}
        
        # Custom prompt templates
        self.custom_prompts = {
            "qa_template": PromptTemplate(
                "Context information is below.\n"
                "---------------------\n"
                "{context_str}\n"
                "---------------------\n"
                "Given the context information above, please answer the question: {query_str}\n"
                "If the context doesn't contain enough information to answer the question, "
                "please say so and provide what information you can based on the context.\n"
            ),
            
            "summary_template": PromptTemplate(
                "Please provide a comprehensive summary of the following information:\n"
                "{context_str}\n"
                "\nSummary:\n"
            ),
            
            "comparison_template": PromptTemplate(
                "Based on the following context:\n"
                "{context_str}\n"
                "\nPlease compare and contrast the concepts mentioned in relation to: {query_str}\n"
                "Provide a structured comparison highlighting similarities and differences.\n"
            )
        }
    
    def load_documents(self) -> List[Document]:
        """Load documents from the specified directory."""
        try:
            if not os.path.exists(self.documents_path):
                self._create_sample_documents()
            
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
            "deep_learning.txt": """
            Deep Learning is a subset of machine learning that uses artificial neural networks
            with multiple layers to model and understand complex patterns in data.
            
            Key characteristics of Deep Learning:
            - Multiple hidden layers (hence "deep")
            - Automatic feature extraction
            - End-to-end learning
            - Requires large amounts of data
            - Computationally intensive
            
            Popular architectures include:
            - Convolutional Neural Networks (CNNs) for image processing
            - Recurrent Neural Networks (RNNs) for sequential data
            - Transformers for natural language processing
            - Generative Adversarial Networks (GANs) for generating new data
            
            Deep learning has revolutionized fields like computer vision, 
            natural language processing, and speech recognition.
            """,
            
            "transformers.txt": """
            Transformers are a type of neural network architecture that has become
            the foundation for most modern large language models.
            
            Key innovations of Transformers:
            - Self-attention mechanism
            - Parallel processing capability
            - Better handling of long sequences
            - Transfer learning capabilities
            
            The Transformer architecture consists of:
            - Encoder: Processes input sequences
            - Decoder: Generates output sequences
            - Attention layers: Focus on relevant parts of input
            - Feed-forward networks: Process attended information
            
            Famous Transformer-based models include:
            - BERT (Bidirectional Encoder Representations from Transformers)
            - GPT (Generative Pre-trained Transformer)
            - T5 (Text-to-Text Transfer Transformer)
            - PaLM (Pathways Language Model)
            
            Transformers have enabled breakthrough performance in tasks like
            machine translation, text summarization, and question answering.
            """,
            
            "llm_applications.txt": """
            Large Language Models (LLMs) have enabled a wide range of applications
            across different domains and industries.
            
            Common LLM Applications:
            1. Conversational AI and Chatbots
            2. Content Generation and Writing Assistance
            3. Code Generation and Programming Help
            4. Language Translation and Localization
            5. Summarization and Information Extraction
            6. Question Answering Systems
            7. Creative Writing and Storytelling
            8. Educational Tutoring and Explanation
            
            Business Use Cases:
            - Customer Service Automation
            - Document Analysis and Processing
            - Market Research and Analysis
            - Legal Document Review
            - Medical Information Processing
            - Scientific Literature Analysis
            
            Technical Approaches:
            - Fine-tuning for specific domains
            - Retrieval-Augmented Generation (RAG)
            - Prompt Engineering and Optimization
            - Multi-modal Integration (text, images, audio)
            
            LLMs are transforming how we interact with information and
            automating many language-related tasks.
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
            
            self.index = VectorStoreIndex.from_documents(
                documents,
                service_context=self.service_context
            )
            
            print("✅ Index created successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error creating index: {str(e)}")
            return False
    
    def create_query_engines(self):
        """Create different types of query engines."""
        if not self.index:
            print("❌ Index not created")
            return
        
        print("🔄 Creating query engines...")
        
        # 1. Default query engine
        self.query_engines["default"] = self.index.as_query_engine()
        
        # 2. Tree summarize query engine
        self.query_engines["tree_summarize"] = self.index.as_query_engine(
            response_mode=ResponseMode.TREE_SUMMARIZE
        )
        
        # 3. Compact query engine
        self.query_engines["compact"] = self.index.as_query_engine(
            response_mode=ResponseMode.COMPACT
        )
        
        # 4. Custom retrieval query engine
        retriever = VectorIndexRetriever(
            index=self.index,
            similarity_top_k=5  # Retrieve top 5 most similar chunks
        )
        
        response_synthesizer = get_response_synthesizer(
            service_context=self.service_context,
            response_mode=ResponseMode.REFINE
        )
        
        self.query_engines["custom_retrieval"] = RetrieverQueryEngine(
            retriever=retriever,
            response_synthesizer=response_synthesizer
        )
        
        # 5. Custom prompt query engine
        qa_prompt = self.custom_prompts["qa_template"]
        
        self.query_engines["custom_prompt"] = self.index.as_query_engine(
            text_qa_template=qa_prompt
        )
        
        print(f"✅ Created {len(self.query_engines)} query engines")
    
    def query_with_engine(self, engine_name: str, question: str) -> Dict[str, Any]:
        """Query using a specific engine."""
        try:
            if engine_name not in self.query_engines:
                return {"error": f"Unknown engine: {engine_name}"}
            
            engine = self.query_engines[engine_name]
            response = engine.query(question)
            
            return {
                "engine": engine_name,
                "question": question,
                "answer": str(response),
                "source_nodes": len(response.source_nodes) if hasattr(response, 'source_nodes') else 0
            }
            
        except Exception as e:
            return {"error": f"Query failed: {str(e)}"}
    
    def compare_engines(self, question: str) -> Dict[str, Any]:
        """Compare responses from different engines."""
        print(f"🔍 Comparing engines for: {question}")
        
        results = {}
        for engine_name in self.query_engines:
            result = self.query_with_engine(engine_name, question)
            results[engine_name] = result
        
        return results
    
    def get_engine_info(self) -> Dict[str, Any]:
        """Get information about available engines."""
        return {
            "available_engines": list(self.query_engines.keys()),
            "descriptions": {
                "default": "Standard query engine with basic retrieval",
                "tree_summarize": "Builds summary tree from retrieved chunks",
                "compact": "Concatenates chunks and refines answer",
                "custom_retrieval": "Custom retriever with top-5 similarity",
                "custom_prompt": "Uses custom QA prompt template"
            }
        }
    
    def initialize(self) -> bool:
        """Initialize the complete system."""
        print("🔄 Initializing Query Engine system...")
        
        # Load documents
        documents = self.load_documents()
        if not documents:
            print("❌ No documents loaded")
            return False
        
        # Create index
        if not self.create_index(documents):
            return False
        
        # Create query engines
        self.create_query_engines()
        
        print("✅ Query Engine system initialized successfully")
        return True

def main():
    """Main function demonstrating query engine features."""
    print("🦙 LlamaIndex Query Engine Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set")
        print("Please set your OpenAI API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize system
        demo = QueryEngineDemo()
        
        if not demo.initialize():
            print("❌ Failed to initialize system")
            sys.exit(1)
        
        # Show available engines
        engine_info = demo.get_engine_info()
        print("\n🛠️ Available Query Engines:")
        for engine in engine_info["available_engines"]:
            description = engine_info["descriptions"].get(engine, "No description")
            print(f"  - {engine}: {description}")
        
        print("\n" + "-" * 50)
        print("🤖 Query Engine Ready! Try different engines and questions.")
        print("Commands:")
        print("  'use <engine>' - Switch to specific engine")
        print("  'compare <question>' - Compare all engines")
        print("  'engines' - Show available engines")
        print("  'quit' - Exit")
        print("-" * 50)
        
        current_engine = "default"
        print(f"Current engine: {current_engine}")
        
        while True:
            # Get user input
            user_input = input("\n🧑 Query: ").strip()
            
            # Handle special commands
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower().startswith('use '):
                new_engine = user_input[4:]
                if new_engine in demo.query_engines:
                    current_engine = new_engine
                    print(f"✅ Switched to {current_engine} engine")
                else:
                    print(f"❌ Unknown engine: {new_engine}")
                continue
            elif user_input.lower().startswith('compare '):
                question = user_input[8:]
                print(f"🔍 Comparing all engines for: {question}")
                results = demo.compare_engines(question)
                
                for engine_name, result in results.items():
                    print(f"\n🛠️ {engine_name}:")
                    if "error" in result:
                        print(f"  ❌ Error: {result['error']}")
                    else:
                        print(f"  Answer: {result['answer']}")
                        if result['source_nodes'] > 0:
                            print(f"  Sources: {result['source_nodes']} chunks")
                continue
            elif user_input.lower() == 'engines':
                engine_info = demo.get_engine_info()
                print("\n🛠️ Available Query Engines:")
                for engine in engine_info["available_engines"]:
                    description = engine_info["descriptions"].get(engine, "No description")
                    marker = "👉" if engine == current_engine else "  "
                    print(f"{marker} {engine}: {description}")
                continue
            elif not user_input:
                continue
            
            # Process query with current engine
            result = demo.query_with_engine(current_engine, user_input)
            
            if "error" in result:
                print(f"❌ Error: {result['error']}")
            else:
                print(f"\n🤖 Answer ({current_engine}): {result['answer']}")
                if result['source_nodes'] > 0:
                    print(f"📚 Sources: {result['source_nodes']} relevant chunks")
            
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()