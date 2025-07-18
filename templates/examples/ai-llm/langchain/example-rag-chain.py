#!/usr/bin/env python3
"""
LangChain RAG (Retrieval-Augmented Generation) Example

This example demonstrates how to build a RAG system using LangChain
for document question-answering with vector embeddings.
"""

import os
import sys
from typing import List, Dict, Any, Optional
from langchain.chat_models import ChatOpenAI
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA
from langchain.document_loaders import DirectoryLoader, TextLoader
from langchain.prompts import PromptTemplate
from langchain.schema import Document
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class RAGSystem:
    """RAG (Retrieval-Augmented Generation) system using LangChain."""
    
    def __init__(self, documents_path: str = "documents"):
        """Initialize the RAG system."""
        self.documents_path = documents_path
        
        # Check for API key
        self.openai_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_key:
            raise ValueError("OPENAI_API_KEY is required for RAG system")
        
        # Initialize components
        self.llm = ChatOpenAI(
            api_key=self.openai_key,
            model_name="gpt-3.5-turbo",
            temperature=0.3  # Lower temperature for more factual responses
        )
        
        self.embeddings = OpenAIEmbeddings(api_key=self.openai_key)
        
        # Text splitter for chunking documents
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len
        )
        
        # Vector store
        self.vectorstore = None
        self.retriever = None
        self.qa_chain = None
    
    def load_documents(self) -> List[Document]:
        """Load documents from the specified directory."""
        try:
            if not os.path.exists(self.documents_path):
                # Create sample documents if directory doesn't exist
                self._create_sample_documents()
            
            # Load documents
            loader = DirectoryLoader(
                self.documents_path,
                glob="*.txt",
                loader_cls=TextLoader
            )
            
            documents = loader.load()
            print(f"📁 Loaded {len(documents)} documents")
            
            return documents
            
        except Exception as e:
            print(f"❌ Error loading documents: {str(e)}")
            return []
    
    def _create_sample_documents(self):
        """Create sample documents for demonstration."""
        os.makedirs(self.documents_path, exist_ok=True)
        
        sample_docs = {
            "langchain_intro.txt": """
            LangChain is a framework for developing applications powered by language models.
            It provides a set of tools and abstractions to work with large language models (LLMs)
            and build complex applications like chatbots, question-answering systems, and agents.
            
            Key components of LangChain include:
            - Models: Interfaces to various LLM providers
            - Prompts: Templates for formatting inputs to models
            - Chains: Sequences of operations for complex workflows
            - Agents: Systems that can use tools and make decisions
            - Memory: Components for maintaining conversation context
            """,
            
            "vector_databases.txt": """
            Vector databases are specialized databases designed to store and query high-dimensional vectors.
            They are essential for applications involving machine learning, particularly for similarity search
            and recommendation systems.
            
            Popular vector databases include:
            - Chroma: Open-source embedding database
            - Pinecone: Managed vector database service
            - Weaviate: Open-source vector search engine
            - Qdrant: Vector similarity search engine
            
            Vector databases enable efficient similarity search, semantic search, and retrieval-augmented generation (RAG).
            """,
            
            "rag_systems.txt": """
            Retrieval-Augmented Generation (RAG) is a technique that combines information retrieval
            with text generation to improve the accuracy and relevance of generated content.
            
            RAG systems work by:
            1. Retrieving relevant documents from a knowledge base
            2. Using retrieved context to augment the generation process
            3. Producing more accurate and contextually relevant responses
            
            Benefits of RAG:
            - Reduces hallucinations in generated text
            - Enables up-to-date information access
            - Provides source attribution for generated content
            - Allows for domain-specific knowledge integration
            """
        }
        
        for filename, content in sample_docs.items():
            filepath = os.path.join(self.documents_path, filename)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content.strip())
        
        print(f"📝 Created {len(sample_docs)} sample documents in {self.documents_path}/")
    
    def create_vector_store(self, documents: List[Document]) -> bool:
        """Create vector store from documents."""
        try:
            # Split documents into chunks
            texts = self.text_splitter.split_documents(documents)
            print(f"📄 Split documents into {len(texts)} chunks")
            
            # Create vector store
            self.vectorstore = Chroma.from_documents(
                documents=texts,
                embedding=self.embeddings,
                persist_directory="./chroma_db"
            )
            
            # Create retriever
            self.retriever = self.vectorstore.as_retriever(
                search_kwargs={"k": 3}  # Return top 3 most relevant chunks
            )
            
            print("✅ Vector store created successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error creating vector store: {str(e)}")
            return False
    
    def create_qa_chain(self) -> bool:
        """Create the question-answering chain."""
        try:
            if not self.retriever:
                print("❌ Retriever not initialized")
                return False
            
            # Custom prompt template
            template = """Use the following pieces of context to answer the question at the end.
            If you don't know the answer, just say that you don't know, don't try to make up an answer.
            
            {context}
            
            Question: {question}
            
            Answer: """
            
            prompt = PromptTemplate(
                template=template,
                input_variables=["context", "question"]
            )
            
            # Create QA chain
            self.qa_chain = RetrievalQA.from_chain_type(
                llm=self.llm,
                chain_type="stuff",
                retriever=self.retriever,
                chain_type_kwargs={"prompt": prompt},
                return_source_documents=True
            )
            
            print("✅ QA chain created successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error creating QA chain: {str(e)}")
            return False
    
    def query(self, question: str) -> Dict[str, Any]:
        """Query the RAG system."""
        try:
            if not self.qa_chain:
                return {"error": "QA chain not initialized"}
            
            # Get answer with source documents
            result = self.qa_chain({"query": question})
            
            # Extract source information
            sources = []
            for doc in result.get("source_documents", []):
                sources.append({
                    "content": doc.page_content[:200] + "..." if len(doc.page_content) > 200 else doc.page_content,
                    "source": doc.metadata.get("source", "Unknown")
                })
            
            return {
                "answer": result["result"],
                "sources": sources,
                "question": question
            }
            
        except Exception as e:
            return {"error": f"Query failed: {str(e)}"}
    
    def similarity_search(self, query: str, k: int = 3) -> List[Dict[str, Any]]:
        """Perform similarity search without question-answering."""
        try:
            if not self.vectorstore:
                return [{"error": "Vector store not initialized"}]
            
            # Perform similarity search
            docs = self.vectorstore.similarity_search(query, k=k)
            
            results = []
            for doc in docs:
                results.append({
                    "content": doc.page_content,
                    "source": doc.metadata.get("source", "Unknown"),
                    "relevance": "High"  # Chroma doesn't return scores by default
                })
            
            return results
            
        except Exception as e:
            return [{"error": f"Similarity search failed: {str(e)}"}]
    
    def initialize(self) -> bool:
        """Initialize the complete RAG system."""
        print("🔄 Initializing RAG system...")
        
        # Load documents
        documents = self.load_documents()
        if not documents:
            print("❌ No documents loaded")
            return False
        
        # Create vector store
        if not self.create_vector_store(documents):
            return False
        
        # Create QA chain
        if not self.create_qa_chain():
            return False
        
        print("✅ RAG system initialized successfully")
        return True

def main():
    """Main function demonstrating RAG system."""
    print("🔗 LangChain RAG System Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set")
        print("Please set your OpenAI API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize RAG system
        rag = RAGSystem()
        
        if not rag.initialize():
            print("❌ Failed to initialize RAG system")
            sys.exit(1)
        
        print("-" * 50)
        print("🤖 RAG System Ready! You can now ask questions about the documents.")
        print("Type 'quit' to exit, 'search <query>' for similarity search")
        print("-" * 50)
        
        while True:
            # Get user input
            user_input = input("\n🧑 Question: ").strip()
            
            # Handle quit command
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif not user_input:
                continue
            
            # Handle similarity search
            if user_input.lower().startswith('search '):
                query = user_input[7:]  # Remove 'search ' prefix
                print(f"🔍 Searching for: {query}")
                results = rag.similarity_search(query)
                
                for i, result in enumerate(results, 1):
                    if "error" in result:
                        print(f"❌ {result['error']}")
                    else:
                        print(f"\n📄 Result {i}:")
                        print(f"Source: {result['source']}")
                        print(f"Content: {result['content']}")
                continue
            
            # Handle regular questions
            print("🤖 Thinking...")
            result = rag.query(user_input)
            
            if "error" in result:
                print(f"❌ Error: {result['error']}")
            else:
                print(f"\n✅ Answer: {result['answer']}")
                
                if result['sources']:
                    print(f"\n📚 Sources:")
                    for i, source in enumerate(result['sources'], 1):
                        print(f"  {i}. {source['source']}")
                        print(f"     {source['content']}")
            
    except KeyboardInterrupt:
        print("\n\n👋 RAG system interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()