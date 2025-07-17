"""
FastAPI + OpenAI Embeddings API Example
RESTful API for text embeddings and semantic search using FastAPI and OpenAI.

Features:
- Text embedding generation
- Batch embedding processing
- Semantic search
- Similarity calculations
- Caching for performance
- Vector operations

Setup:
1. pip install fastapi uvicorn openai python-dotenv tiktoken numpy scikit-learn slowapi
2. Set OPENAI_API_KEY environment variable
3. uvicorn example-embeddings-api:app --reload

Environment variables:
- OPENAI_API_KEY: Your OpenAI API key
- OPENAI_EMBEDDING_MODEL: Model to use (default: text-embedding-3-small)
- SECRET_KEY: FastAPI secret key
- RATE_LIMIT_PER_MINUTE: Rate limit (default: 100)
- CACHE_EXPIRY_MINUTES: Cache expiry time (default: 60)
"""

from fastapi import FastAPI, HTTPException, Depends, Request, BackgroundTasks
from pydantic import BaseModel, validator
from typing import List, Dict, Any, Optional
import os
import json
import time
import hashlib
from datetime import datetime, timedelta
from openai import OpenAI
from dotenv import load_dotenv
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# FastAPI app
app = FastAPI(
    title="Embeddings API",
    description="OpenAI-powered embeddings API with FastAPI",
    version="1.0.0"
)

# Add rate limiter to app
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Configuration
class Settings:
    def __init__(self):
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY environment variable is required")
        
        self.embedding_model = os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")
        self.rate_limit = os.getenv("RATE_LIMIT_PER_MINUTE", "100")
        self.cache_expiry = int(os.getenv("CACHE_EXPIRY_MINUTES", "60"))
        
        # Embedding model pricing (per 1M tokens)
        self.pricing = {
            "text-embedding-3-small": 0.02,
            "text-embedding-3-large": 0.13,
            "text-embedding-ada-002": 0.10
        }

settings = Settings()

# OpenAI client
openai_client = OpenAI(api_key=settings.openai_api_key)

# In-memory cache (use Redis in production)
embeddings_cache: Dict[str, Dict[str, Any]] = {}
usage_stats: Dict[str, Dict[str, Any]] = {}

# Pydantic models
class EmbeddingRequest(BaseModel):
    text: str
    model: Optional[str] = None
    use_cache: bool = True
    
    @validator('text')
    def validate_text(cls, v):
        if not v.strip():
            raise ValueError('Text cannot be empty')
        if len(v) > 50000:
            raise ValueError('Text too long (max 50000 characters)')
        return v.strip()

class BatchEmbeddingRequest(BaseModel):
    texts: List[str]
    model: Optional[str] = None
    use_cache: bool = True
    
    @validator('texts')
    def validate_texts(cls, v):
        if not v:
            raise ValueError('Texts list cannot be empty')
        if len(v) > 100:
            raise ValueError('Too many texts (max 100 per batch)')
        for text in v:
            if not text.strip():
                raise ValueError('Text cannot be empty')
        return [text.strip() for text in v]

class SimilarityRequest(BaseModel):
    text1: str
    text2: str
    model: Optional[str] = None
    
    @validator('text1', 'text2')
    def validate_texts(cls, v):
        if not v.strip():
            raise ValueError('Text cannot be empty')
        return v.strip()

class SearchRequest(BaseModel):
    query: str
    documents: List[str]
    model: Optional[str] = None
    top_k: int = 5
    threshold: float = 0.0
    
    @validator('query')
    def validate_query(cls, v):
        if not v.strip():
            raise ValueError('Query cannot be empty')
        return v.strip()
    
    @validator('documents')
    def validate_documents(cls, v):
        if not v:
            raise ValueError('Documents list cannot be empty')
        if len(v) > 500:
            raise ValueError('Too many documents (max 500)')
        return [doc.strip() for doc in v if doc.strip()]
    
    @validator('top_k')
    def validate_top_k(cls, v):
        if v < 1:
            raise ValueError('top_k must be at least 1')
        return v

class EmbeddingResponse(BaseModel):
    text: str
    embedding: List[float]
    model: str
    tokens_used: int
    cost: float
    cached: bool
    processing_time: float

class BatchEmbeddingResponse(BaseModel):
    results: List[EmbeddingResponse]
    total_tokens: int
    total_cost: float
    processing_time: float

class SimilarityResponse(BaseModel):
    similarity: float
    text1: str
    text2: str
    model: str
    tokens_used: int
    cost: float
    processing_time: float

class SearchResponse(BaseModel):
    query: str
    results: List[Dict[str, Any]]
    model: str
    tokens_used: int
    cost: float
    processing_time: float

# Utility functions
def count_tokens(text: str) -> int:
    """Estimate token count for text"""
    return len(text) // 4  # Rough estimation

def calculate_cost(tokens: int, model: str) -> float:
    """Calculate cost based on token usage"""
    rate = settings.pricing.get(model, 0.02)
    return (tokens / 1000000) * rate

def get_cache_key(text: str, model: str) -> str:
    """Generate cache key for text and model"""
    return hashlib.md5(f"{model}:{text}".encode()).hexdigest()

def is_cache_valid(cache_entry: Dict[str, Any]) -> bool:
    """Check if cache entry is still valid"""
    expiry_time = cache_entry.get("expires_at")
    if not expiry_time:
        return False
    return datetime.utcnow() < expiry_time

def get_embedding(text: str, model: str, use_cache: bool = True) -> Dict[str, Any]:
    """Get embedding for a single text"""
    cache_key = get_cache_key(text, model)
    
    # Check cache
    if use_cache and cache_key in embeddings_cache:
        cache_entry = embeddings_cache[cache_key]
        if is_cache_valid(cache_entry):
            return {
                "embedding": cache_entry["embedding"],
                "tokens_used": 0,
                "cost": 0.0,
                "cached": True
            }
    
    try:
        start_time = time.time()
        
        # Count tokens
        tokens = count_tokens(text)
        
        # Get embedding
        response = openai_client.embeddings.create(
            input=text,
            model=model
        )
        
        embedding = response.data[0].embedding
        cost = calculate_cost(tokens, model)
        processing_time = time.time() - start_time
        
        # Cache the result
        if use_cache:
            embeddings_cache[cache_key] = {
                "embedding": embedding,
                "expires_at": datetime.utcnow() + timedelta(minutes=settings.cache_expiry)
            }
        
        return {
            "embedding": embedding,
            "tokens_used": tokens,
            "cost": cost,
            "cached": False,
            "processing_time": processing_time
        }
        
    except Exception as e:
        logger.error(f"Embedding error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

def update_usage_stats(client_ip: str, tokens: int, cost: float):
    """Update usage statistics"""
    if client_ip not in usage_stats:
        usage_stats[client_ip] = {
            "total_requests": 0,
            "total_tokens": 0,
            "total_cost": 0.0,
            "first_request": datetime.utcnow(),
            "last_request": datetime.utcnow()
        }
    
    stats = usage_stats[client_ip]
    stats["total_requests"] += 1
    stats["total_tokens"] += tokens
    stats["total_cost"] += cost
    stats["last_request"] = datetime.utcnow()

# Dependencies
def get_client_ip(request: Request) -> str:
    """Get client IP address"""
    return get_remote_address(request)

# Routes
@app.get("/", tags=["root"])
async def root():
    """API health check"""
    return {
        "message": "Embeddings API is running",
        "version": "1.0.0",
        "model": settings.embedding_model,
        "endpoints": {
            "embedding": "/embeddings",
            "batch": "/embeddings/batch",
            "similarity": "/similarity",
            "search": "/search"
        }
    }

@app.post("/embeddings", response_model=EmbeddingResponse, tags=["embeddings"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def create_embedding(
    request: Request,
    embedding_request: EmbeddingRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Generate embedding for a single text"""
    start_time = time.time()
    
    model = embedding_request.model or settings.embedding_model
    
    # Get embedding
    result = get_embedding(embedding_request.text, model, embedding_request.use_cache)
    
    processing_time = time.time() - start_time
    
    # Update usage stats in background
    background_tasks.add_task(
        update_usage_stats,
        client_ip,
        result["tokens_used"],
        result["cost"]
    )
    
    return EmbeddingResponse(
        text=embedding_request.text,
        embedding=result["embedding"],
        model=model,
        tokens_used=result["tokens_used"],
        cost=result["cost"],
        cached=result["cached"],
        processing_time=processing_time
    )

@app.post("/embeddings/batch", response_model=BatchEmbeddingResponse, tags=["embeddings"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def create_batch_embeddings(
    request: Request,
    batch_request: BatchEmbeddingRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Generate embeddings for multiple texts"""
    start_time = time.time()
    
    model = batch_request.model or settings.embedding_model
    results = []
    total_tokens = 0
    total_cost = 0.0
    
    for text in batch_request.texts:
        result = get_embedding(text, model, batch_request.use_cache)
        
        results.append(EmbeddingResponse(
            text=text,
            embedding=result["embedding"],
            model=model,
            tokens_used=result["tokens_used"],
            cost=result["cost"],
            cached=result["cached"],
            processing_time=result.get("processing_time", 0.0)
        ))
        
        total_tokens += result["tokens_used"]
        total_cost += result["cost"]
    
    processing_time = time.time() - start_time
    
    # Update usage stats in background
    background_tasks.add_task(
        update_usage_stats,
        client_ip,
        total_tokens,
        total_cost
    )
    
    return BatchEmbeddingResponse(
        results=results,
        total_tokens=total_tokens,
        total_cost=total_cost,
        processing_time=processing_time
    )

@app.post("/similarity", response_model=SimilarityResponse, tags=["similarity"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def calculate_similarity(
    request: Request,
    similarity_request: SimilarityRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Calculate similarity between two texts"""
    start_time = time.time()
    
    model = similarity_request.model or settings.embedding_model
    
    # Get embeddings
    result1 = get_embedding(similarity_request.text1, model)
    result2 = get_embedding(similarity_request.text2, model)
    
    # Calculate cosine similarity
    embedding1 = np.array(result1["embedding"]).reshape(1, -1)
    embedding2 = np.array(result2["embedding"]).reshape(1, -1)
    
    similarity = cosine_similarity(embedding1, embedding2)[0][0]
    
    processing_time = time.time() - start_time
    total_tokens = result1["tokens_used"] + result2["tokens_used"]
    total_cost = result1["cost"] + result2["cost"]
    
    # Update usage stats in background
    background_tasks.add_task(
        update_usage_stats,
        client_ip,
        total_tokens,
        total_cost
    )
    
    return SimilarityResponse(
        similarity=float(similarity),
        text1=similarity_request.text1,
        text2=similarity_request.text2,
        model=model,
        tokens_used=total_tokens,
        cost=total_cost,
        processing_time=processing_time
    )

@app.post("/search", response_model=SearchResponse, tags=["search"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def semantic_search(
    request: Request,
    search_request: SearchRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Perform semantic search"""
    start_time = time.time()
    
    model = search_request.model or settings.embedding_model
    
    # Get query embedding
    query_result = get_embedding(search_request.query, model)
    query_embedding = np.array(query_result["embedding"])
    
    # Get document embeddings and calculate similarities
    results = []
    total_tokens = query_result["tokens_used"]
    total_cost = query_result["cost"]
    
    for i, doc in enumerate(search_request.documents):
        doc_result = get_embedding(doc, model)
        doc_embedding = np.array(doc_result["embedding"])
        
        # Calculate similarity
        similarity = cosine_similarity(
            query_embedding.reshape(1, -1),
            doc_embedding.reshape(1, -1)
        )[0][0]
        
        # Apply threshold filter
        if similarity >= search_request.threshold:
            results.append({
                "document": doc,
                "similarity": float(similarity),
                "index": i,
                "cached": doc_result["cached"]
            })
        
        total_tokens += doc_result["tokens_used"]
        total_cost += doc_result["cost"]
    
    # Sort by similarity and return top k
    results.sort(key=lambda x: x["similarity"], reverse=True)
    results = results[:search_request.top_k]
    
    processing_time = time.time() - start_time
    
    # Update usage stats in background
    background_tasks.add_task(
        update_usage_stats,
        client_ip,
        total_tokens,
        total_cost
    )
    
    return SearchResponse(
        query=search_request.query,
        results=results,
        model=model,
        tokens_used=total_tokens,
        cost=total_cost,
        processing_time=processing_time
    )

@app.get("/stats", tags=["stats"])
async def get_stats(client_ip: str = Depends(get_client_ip)):
    """Get usage statistics"""
    if client_ip not in usage_stats:
        return {
            "total_requests": 0,
            "total_tokens": 0,
            "total_cost": 0.0,
            "cached_embeddings": len(embeddings_cache)
        }
    
    stats = usage_stats[client_ip]
    return {
        "total_requests": stats["total_requests"],
        "total_tokens": stats["total_tokens"],
        "total_cost": stats["total_cost"],
        "cached_embeddings": len(embeddings_cache),
        "first_request": stats["first_request"],
        "last_request": stats["last_request"]
    }

@app.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint"""
    try:
        # Test OpenAI connection
        test_response = openai_client.embeddings.create(
            input="test",
            model="text-embedding-3-small"
        )
        
        return {
            "status": "healthy",
            "openai": "connected",
            "model": settings.embedding_model,
            "cached_embeddings": len(embeddings_cache)
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "openai": "disconnected",
            "error": str(e)
        }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return {"error": exc.detail, "status_code": exc.status_code}

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unexpected error: {exc}")
    return {"error": "Internal server error", "status_code": 500}

# Middleware for logging
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.method} {request.url.path} - "
        f"Status: {response.status_code} - "
        f"Time: {process_time:.3f}s"
    )
    
    return response

# Run with: uvicorn example-embeddings-api:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")