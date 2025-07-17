"""
FastAPI + LangChain RAG System Example
Retrieval-Augmented Generation (RAG) system using FastAPI and LangChain.

Features:
- Document upload and processing
- Vector embeddings with Chroma
- Semantic search and retrieval
- Question answering with context
- Document management
- Conversation history
- Source attribution

Setup:
1. pip install fastapi uvicorn langchain openai chromadb pypdf python-dotenv
2. Set OPENAI_API_KEY environment variable
3. uvicorn example-rag-system:app --reload

Environment variables:
- OPENAI_API_KEY: Your OpenAI API key
- CHROMA_PERSIST_DIR: Directory for Chroma database (default: ./chroma_db)
- OPENAI_MODEL: Model to use (default: gpt-4)
- CHUNK_SIZE: Text chunk size (default: 1000)
- CHUNK_OVERLAP: Text chunk overlap (default: 200)
"""

from fastapi import FastAPI, HTTPException, UploadFile, File, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import List, Dict, Any, Optional
import os
import uuid
import time
from datetime import datetime
from dotenv import load_dotenv
import logging

# LangChain imports
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import PyPDFLoader, TextLoader
from langchain.chains import RetrievalQA
from langchain.llms import OpenAI
from langchain.schema import Document
from langchain.callbacks import get_openai_callback
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationalRetrievalChain

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY environment variable is required")

CHROMA_PERSIST_DIR = os.getenv("CHROMA_PERSIST_DIR", "./chroma_db")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4")
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", "1000"))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP", "200"))

# FastAPI app
app = FastAPI(
    title="RAG System API",
    description="Retrieval-Augmented Generation system with LangChain and FastAPI",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize LangChain components
embeddings = OpenAIEmbeddings()
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=CHUNK_SIZE,
    chunk_overlap=CHUNK_OVERLAP,
    separators=["\n\n", "\n", " ", ""]
)
llm = OpenAI(temperature=0.7, model_name=OPENAI_MODEL)

# Initialize vector store
vectorstore = Chroma(
    persist_directory=CHROMA_PERSIST_DIR,
    embedding_function=embeddings
)

# Document storage
documents_db = {}
conversations_db = {}

# Pydantic models
class DocumentUpload(BaseModel):
    title: str = Field(..., description="Document title")
    description: Optional[str] = Field(None, description="Document description")
    category: Optional[str] = Field(None, description="Document category")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")

class DocumentResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    category: Optional[str]
    filename: str
    file_size: int
    chunks_count: int
    created_at: datetime
    metadata: Optional[Dict[str, Any]]

class QueryRequest(BaseModel):
    question: str = Field(..., description="Question to ask")
    top_k: int = Field(5, ge=1, le=20, description="Number of relevant chunks to retrieve")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for context")
    include_sources: bool = Field(True, description="Include source documents in response")
    
    @validator('question')
    def validate_question(cls, v):
        if not v.strip():
            raise ValueError('Question cannot be empty')
        if len(v) > 1000:
            raise ValueError('Question too long (max 1000 characters)')
        return v.strip()

class QueryResponse(BaseModel):
    answer: str
    sources: Optional[List[Dict[str, Any]]] = None
    conversation_id: Optional[str] = None
    tokens_used: int
    cost: float
    processing_time: float
    confidence: Optional[float] = None

class SearchRequest(BaseModel):
    query: str = Field(..., description="Search query")
    top_k: int = Field(5, ge=1, le=20, description="Number of results to return")
    min_score: float = Field(0.0, ge=0.0, le=1.0, description="Minimum similarity score")
    category: Optional[str] = Field(None, description="Filter by category")

class SearchResult(BaseModel):
    content: str
    score: float
    document_id: str
    document_title: str
    chunk_index: int
    metadata: Dict[str, Any]

class ConversationResponse(BaseModel):
    conversation_id: str
    message_count: int
    created_at: datetime
    last_message_at: datetime

# Document processing class
class DocumentProcessor:
    def __init__(self):
        self.supported_types = {
            '.pdf': PyPDFLoader,
            '.txt': TextLoader,
        }
    
    def process_file(self, file_path: str, metadata: Dict[str, Any] = None) -> List[Document]:
        """Process uploaded file and return documents"""
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext not in self.supported_types:
            raise ValueError(f"Unsupported file type: {file_ext}")
        
        loader_class = self.supported_types[file_ext]
        loader = loader_class(file_path)
        
        try:
            documents = loader.load()
            
            # Add metadata to documents
            if metadata:
                for doc in documents:
                    doc.metadata.update(metadata)
            
            return documents
        except Exception as e:
            logger.error(f"Error processing file {file_path}: {e}")
            raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")

# RAG system class
class RAGSystem:
    def __init__(self, vectorstore: Chroma, llm: OpenAI):
        self.vectorstore = vectorstore
        self.llm = llm
        self.text_splitter = text_splitter
        self.conversations = {}
    
    def add_documents(self, documents: List[Document], document_id: str) -> int:
        """Add documents to vector store"""
        # Split documents into chunks
        chunks = self.text_splitter.split_documents(documents)
        
        # Add document ID to metadata
        for i, chunk in enumerate(chunks):
            chunk.metadata.update({
                'document_id': document_id,
                'chunk_index': i
            })
        
        # Add to vector store
        self.vectorstore.add_documents(chunks)
        self.vectorstore.persist()
        
        return len(chunks)
    
    def query(self, question: str, top_k: int = 5, conversation_id: str = None) -> Dict[str, Any]:
        """Query the RAG system"""
        start_time = time.time()
        
        with get_openai_callback() as cb:
            if conversation_id and conversation_id in self.conversations:
                # Use conversational chain for follow-up questions
                chain = self.conversations[conversation_id]
                result = chain({"question": question})
                
                answer = result.get("answer", "")
                source_docs = result.get("source_documents", [])
            else:
                # Use standard retrieval QA
                retriever = self.vectorstore.as_retriever(search_kwargs={"k": top_k})
                qa_chain = RetrievalQA.from_chain_type(
                    llm=self.llm,
                    chain_type="stuff",
                    retriever=retriever,
                    return_source_documents=True
                )
                
                result = qa_chain({"query": question})
                answer = result.get("result", "")
                source_docs = result.get("source_documents", [])
                
                # Create conversation for follow-up
                if conversation_id:
                    memory = ConversationBufferMemory(
                        memory_key="chat_history",
                        return_messages=True
                    )
                    
                    self.conversations[conversation_id] = ConversationalRetrievalChain.from_llm(
                        llm=self.llm,
                        retriever=retriever,
                        memory=memory,
                        return_source_documents=True
                    )
        
        processing_time = time.time() - start_time
        
        # Process source documents
        sources = []
        for doc in source_docs:
            sources.append({
                "content": doc.page_content,
                "document_id": doc.metadata.get("document_id", ""),
                "document_title": doc.metadata.get("title", ""),
                "chunk_index": doc.metadata.get("chunk_index", 0),
                "metadata": doc.metadata
            })
        
        return {
            "answer": answer,
            "sources": sources,
            "tokens_used": cb.total_tokens,
            "cost": cb.total_cost,
            "processing_time": processing_time
        }
    
    def search(self, query: str, top_k: int = 5, min_score: float = 0.0, category: str = None) -> List[Dict[str, Any]]:
        """Search documents by similarity"""
        # Build filter
        filter_dict = {}
        if category:
            filter_dict["category"] = category
        
        # Perform similarity search
        results = self.vectorstore.similarity_search_with_score(
            query, 
            k=top_k,
            filter=filter_dict if filter_dict else None
        )
        
        # Process results
        search_results = []
        for doc, score in results:
            if score >= min_score:
                search_results.append({
                    "content": doc.page_content,
                    "score": score,
                    "document_id": doc.metadata.get("document_id", ""),
                    "document_title": doc.metadata.get("title", ""),
                    "chunk_index": doc.metadata.get("chunk_index", 0),
                    "metadata": doc.metadata
                })
        
        return search_results
    
    def delete_document(self, document_id: str) -> bool:
        """Delete all chunks of a document"""
        try:
            # Get all chunks for this document
            results = self.vectorstore.similarity_search("", k=10000)
            ids_to_delete = [
                chunk.metadata.get("chunk_id") 
                for chunk in results 
                if chunk.metadata.get("document_id") == document_id
            ]
            
            if ids_to_delete:
                self.vectorstore.delete(ids_to_delete)
                self.vectorstore.persist()
                return True
            
            return False
        except Exception as e:
            logger.error(f"Error deleting document {document_id}: {e}")
            return False

# Initialize components
document_processor = DocumentProcessor()
rag_system = RAGSystem(vectorstore, llm)

# Dependencies
def get_rag_system() -> RAGSystem:
    return rag_system

# Routes
@app.get("/", tags=["root"])
def root():
    """API root endpoint"""
    return {
        "message": "RAG System API",
        "version": "1.0.0",
        "endpoints": {
            "upload": "/documents/upload",
            "query": "/rag/query",
            "search": "/rag/search",
            "documents": "/documents/"
        }
    }

@app.post("/documents/upload", response_model=DocumentResponse, tags=["documents"])
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    title: str = "",
    description: str = "",
    category: str = "",
    rag: RAGSystem = Depends(get_rag_system)
):
    """Upload and process a document"""
    # Generate document ID
    document_id = str(uuid.uuid4())
    
    # Validate file type
    if not file.filename.endswith(('.pdf', '.txt')):
        raise HTTPException(status_code=400, detail="Unsupported file type")
    
    # Save uploaded file
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    
    file_path = os.path.join(upload_dir, f"{document_id}_{file.filename}")
    
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    # Process document
    metadata = {
        "document_id": document_id,
        "title": title or file.filename,
        "description": description,
        "category": category,
        "filename": file.filename,
        "file_size": len(content),
        "upload_date": datetime.utcnow().isoformat()
    }
    
    try:
        # Process file and add to vector store
        documents = document_processor.process_file(file_path, metadata)
        chunks_count = rag.add_documents(documents, document_id)
        
        # Store document metadata
        doc_info = {
            "id": document_id,
            "title": metadata["title"],
            "description": description,
            "category": category,
            "filename": file.filename,
            "file_size": len(content),
            "chunks_count": chunks_count,
            "created_at": datetime.utcnow(),
            "metadata": metadata
        }
        
        documents_db[document_id] = doc_info
        
        # Clean up uploaded file
        background_tasks.add_task(os.remove, file_path)
        
        return DocumentResponse(**doc_info)
        
    except Exception as e:
        # Clean up on error
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"Error processing document: {str(e)}")

@app.post("/rag/query", response_model=QueryResponse, tags=["rag"])
async def query_documents(
    query_request: QueryRequest,
    rag: RAGSystem = Depends(get_rag_system)
):
    """Query documents using RAG"""
    try:
        # Generate conversation ID if not provided
        conversation_id = query_request.conversation_id or str(uuid.uuid4())
        
        # Query the RAG system
        result = rag.query(
            question=query_request.question,
            top_k=query_request.top_k,
            conversation_id=conversation_id
        )
        
        # Update conversation tracking
        if conversation_id not in conversations_db:
            conversations_db[conversation_id] = {
                "conversation_id": conversation_id,
                "message_count": 0,
                "created_at": datetime.utcnow(),
                "last_message_at": datetime.utcnow()
            }
        
        conversations_db[conversation_id]["message_count"] += 1
        conversations_db[conversation_id]["last_message_at"] = datetime.utcnow()
        
        return QueryResponse(
            answer=result["answer"],
            sources=result["sources"] if query_request.include_sources else None,
            conversation_id=conversation_id,
            tokens_used=result["tokens_used"],
            cost=result["cost"],
            processing_time=result["processing_time"]
        )
        
    except Exception as e:
        logger.error(f"Error querying documents: {e}")
        raise HTTPException(status_code=500, detail=f"Error querying documents: {str(e)}")

@app.post("/rag/search", response_model=List[SearchResult], tags=["rag"])
async def search_documents(
    search_request: SearchRequest,
    rag: RAGSystem = Depends(get_rag_system)
):
    """Search documents by similarity"""
    try:
        results = rag.search(
            query=search_request.query,
            top_k=search_request.top_k,
            min_score=search_request.min_score,
            category=search_request.category
        )
        
        return [SearchResult(**result) for result in results]
        
    except Exception as e:
        logger.error(f"Error searching documents: {e}")
        raise HTTPException(status_code=500, detail=f"Error searching documents: {str(e)}")

@app.get("/documents/", response_model=List[DocumentResponse], tags=["documents"])
async def list_documents(
    category: Optional[str] = None,
    limit: int = 100
):
    """List all documents"""
    documents = list(documents_db.values())
    
    if category:
        documents = [doc for doc in documents if doc.get("category") == category]
    
    return documents[:limit]

@app.get("/documents/{document_id}", response_model=DocumentResponse, tags=["documents"])
async def get_document(document_id: str):
    """Get document by ID"""
    if document_id not in documents_db:
        raise HTTPException(status_code=404, detail="Document not found")
    
    return DocumentResponse(**documents_db[document_id])

@app.delete("/documents/{document_id}", tags=["documents"])
async def delete_document(
    document_id: str,
    rag: RAGSystem = Depends(get_rag_system)
):
    """Delete a document"""
    if document_id not in documents_db:
        raise HTTPException(status_code=404, detail="Document not found")
    
    # Delete from vector store
    success = rag.delete_document(document_id)
    
    if success:
        # Delete from documents database
        del documents_db[document_id]
        return {"message": "Document deleted successfully"}
    else:
        raise HTTPException(status_code=500, detail="Error deleting document")

@app.get("/conversations/", response_model=List[ConversationResponse], tags=["conversations"])
async def list_conversations():
    """List all conversations"""
    conversations = []
    for conv_data in conversations_db.values():
        conversations.append(ConversationResponse(**conv_data))
    
    return conversations

@app.delete("/conversations/{conversation_id}", tags=["conversations"])
async def delete_conversation(
    conversation_id: str,
    rag: RAGSystem = Depends(get_rag_system)
):
    """Delete a conversation"""
    if conversation_id not in conversations_db:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    # Remove from conversation tracking
    del conversations_db[conversation_id]
    
    # Remove from RAG system
    if conversation_id in rag.conversations:
        del rag.conversations[conversation_id]
    
    return {"message": "Conversation deleted successfully"}

@app.get("/stats", tags=["stats"])
async def get_stats():
    """Get system statistics"""
    return {
        "documents_count": len(documents_db),
        "conversations_count": len(conversations_db),
        "vector_store_size": vectorstore._collection.count() if hasattr(vectorstore, '_collection') else 0,
        "categories": list(set(doc.get("category", "") for doc in documents_db.values() if doc.get("category")))
    }

@app.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint"""
    try:
        # Test vector store connection
        vectorstore.similarity_search("test", k=1)
        
        return {
            "status": "healthy",
            "vectorstore": "connected",
            "documents": len(documents_db),
            "conversations": len(conversations_db)
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return {"error": exc.detail, "status_code": exc.status_code}

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unexpected error: {exc}")
    return {"error": "Internal server error", "status_code": 500}

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize application on startup"""
    logger.info("RAG System API starting up...")
    
    # Create directories
    os.makedirs("uploads", exist_ok=True)
    os.makedirs(CHROMA_PERSIST_DIR, exist_ok=True)
    
    logger.info("RAG System API started successfully!")

# Run with: uvicorn example-rag-system:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")