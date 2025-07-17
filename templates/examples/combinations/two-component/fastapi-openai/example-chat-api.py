"""
FastAPI + OpenAI Chat API Example
RESTful API for AI-powered chat using FastAPI and OpenAI.

Features:
- Chat completion endpoints
- Conversation history management
- Token usage tracking
- Cost monitoring
- Error handling
- Rate limiting
- Streaming responses

Setup:
1. pip install fastapi uvicorn openai python-dotenv pydantic tiktoken slowapi
2. Set OPENAI_API_KEY environment variable
3. uvicorn example-chat-api:app --reload

Environment variables:
- OPENAI_API_KEY: Your OpenAI API key
- OPENAI_MODEL: Model to use (default: gpt-4)
- SECRET_KEY: FastAPI secret key
- DEBUG: Enable debug mode (default: True)
"""

from fastapi import FastAPI, HTTPException, Depends, Request, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, validator
from typing import List, Dict, Any, Optional, AsyncGenerator
import os
import asyncio
import json
import time
from datetime import datetime, timedelta
from openai import OpenAI, AsyncOpenAI
from dotenv import load_dotenv
import tiktoken
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
    title="AI Chat API",
    description="OpenAI-powered chat API with FastAPI",
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
        
        self.openai_model = os.getenv("OPENAI_MODEL", "gpt-4")
        self.temperature = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
        self.max_tokens = int(os.getenv("OPENAI_MAX_TOKENS", "1000"))
        self.debug = os.getenv("DEBUG", "True").lower() == "true"
        self.rate_limit = os.getenv("RATE_LIMIT_PER_MINUTE", "60")
        self.daily_budget = float(os.getenv("DAILY_BUDGET", "10.00"))

settings = Settings()

# OpenAI clients
openai_client = OpenAI(api_key=settings.openai_api_key)
async_openai_client = AsyncOpenAI(api_key=settings.openai_api_key)

# In-memory storage (use database in production)
conversations: Dict[str, List[Dict[str, str]]] = {}
usage_stats: Dict[str, Dict[str, Any]] = {}

# Pydantic models
class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    model: Optional[str] = None
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None
    
    @validator('message')
    def validate_message(cls, v):
        if not v.strip():
            raise ValueError('Message cannot be empty')
        if len(v) > 10000:
            raise ValueError('Message too long (max 10000 characters)')
        return v.strip()

class ChatResponse(BaseModel):
    response: str
    conversation_id: str
    tokens_used: int
    cost: float
    model: str
    processing_time: float

class ConversationRequest(BaseModel):
    messages: List[Dict[str, str]]
    model: Optional[str] = None
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None
    
    @validator('messages')
    def validate_messages(cls, v):
        if not v:
            raise ValueError('Messages cannot be empty')
        for msg in v:
            if 'role' not in msg or 'content' not in msg:
                raise ValueError('Each message must have role and content')
            if msg['role'] not in ['system', 'user', 'assistant']:
                raise ValueError('Role must be system, user, or assistant')
        return v

class StreamingChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    model: Optional[str] = None
    temperature: Optional[float] = None

class UsageStats(BaseModel):
    total_requests: int
    total_tokens: int
    total_cost: float
    conversations: int
    average_tokens_per_request: float
    average_cost_per_request: float

# Utility functions
def count_tokens(text: str, model: str = "gpt-4") -> int:
    """Count tokens in text using tiktoken"""
    try:
        encoding = tiktoken.encoding_for_model(model)
        return len(encoding.encode(text))
    except Exception:
        # Fallback estimation
        return len(text.split()) * 1.3

def calculate_cost(tokens: int, model: str) -> float:
    """Calculate cost based on token usage"""
    pricing = {
        "gpt-4": 0.03,
        "gpt-4-turbo": 0.01,
        "gpt-3.5-turbo": 0.002
    }
    rate = pricing.get(model, 0.03)
    return (tokens / 1000) * rate

def get_conversation_id() -> str:
    """Generate unique conversation ID"""
    import uuid
    return str(uuid.uuid4())

def update_usage_stats(client_ip: str, tokens: int, cost: float, processing_time: float):
    """Update usage statistics"""
    if client_ip not in usage_stats:
        usage_stats[client_ip] = {
            "total_requests": 0,
            "total_tokens": 0,
            "total_cost": 0.0,
            "conversations": set(),
            "first_request": datetime.utcnow(),
            "last_request": datetime.utcnow()
        }
    
    stats = usage_stats[client_ip]
    stats["total_requests"] += 1
    stats["total_tokens"] += tokens
    stats["total_cost"] += cost
    stats["last_request"] = datetime.utcnow()
    stats["processing_times"] = stats.get("processing_times", [])
    stats["processing_times"].append(processing_time)

def check_daily_budget(client_ip: str, estimated_cost: float):
    """Check if user is within daily budget"""
    if client_ip in usage_stats:
        current_cost = usage_stats[client_ip]["total_cost"]
        if current_cost + estimated_cost > settings.daily_budget:
            raise HTTPException(
                status_code=402,
                detail=f"Daily budget of ${settings.daily_budget} exceeded"
            )

# Dependencies
def get_client_ip(request: Request) -> str:
    """Get client IP address"""
    return get_remote_address(request)

# Routes
@app.get("/", tags=["root"])
async def root():
    """API health check"""
    return {
        "message": "AI Chat API is running",
        "version": "1.0.0",
        "model": settings.openai_model,
        "endpoints": {
            "chat": "/chat",
            "stream": "/chat/stream",
            "conversation": "/chat/conversation",
            "stats": "/chat/stats"
        }
    }

@app.post("/chat", response_model=ChatResponse, tags=["chat"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def chat_completion(
    request: Request,
    chat_request: ChatRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Single chat completion"""
    start_time = time.time()
    
    try:
        # Use provided values or defaults
        model = chat_request.model or settings.openai_model
        temperature = chat_request.temperature or settings.temperature
        max_tokens = chat_request.max_tokens or settings.max_tokens
        
        # Estimate cost and check budget
        estimated_tokens = count_tokens(chat_request.message, model) + max_tokens
        estimated_cost = calculate_cost(estimated_tokens, model)
        check_daily_budget(client_ip, estimated_cost)
        
        # Get or create conversation
        conversation_id = chat_request.conversation_id or get_conversation_id()
        if conversation_id not in conversations:
            conversations[conversation_id] = []
        
        # Add user message to conversation
        conversations[conversation_id].append({
            "role": "user",
            "content": chat_request.message
        })
        
        # Prepare messages for API
        messages = conversations[conversation_id]
        
        # Make API call
        response = openai_client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens
        )
        
        # Extract response
        assistant_message = response.choices[0].message.content
        
        # Add assistant response to conversation
        conversations[conversation_id].append({
            "role": "assistant",
            "content": assistant_message
        })
        
        # Calculate metrics
        tokens_used = response.usage.total_tokens
        cost = calculate_cost(tokens_used, model)
        processing_time = time.time() - start_time
        
        # Update usage stats in background
        background_tasks.add_task(
            update_usage_stats,
            client_ip,
            tokens_used,
            cost,
            processing_time
        )
        
        # Track conversation
        if client_ip in usage_stats:
            usage_stats[client_ip]["conversations"].add(conversation_id)
        
        logger.info(f"Chat completion: {tokens_used} tokens, ${cost:.4f}, {processing_time:.2f}s")
        
        return ChatResponse(
            response=assistant_message,
            conversation_id=conversation_id,
            tokens_used=tokens_used,
            cost=cost,
            model=model,
            processing_time=processing_time
        )
        
    except Exception as e:
        logger.error(f"Chat completion error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat/stream", tags=["chat"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def streaming_chat(
    request: Request,
    chat_request: StreamingChatRequest,
    client_ip: str = Depends(get_client_ip)
):
    """Streaming chat completion"""
    try:
        # Use provided values or defaults
        model = chat_request.model or settings.openai_model
        temperature = chat_request.temperature or settings.temperature
        
        # Estimate cost and check budget
        estimated_tokens = count_tokens(chat_request.message, model) + settings.max_tokens
        estimated_cost = calculate_cost(estimated_tokens, model)
        check_daily_budget(client_ip, estimated_cost)
        
        # Get or create conversation
        conversation_id = chat_request.conversation_id or get_conversation_id()
        if conversation_id not in conversations:
            conversations[conversation_id] = []
        
        # Add user message to conversation
        conversations[conversation_id].append({
            "role": "user",
            "content": chat_request.message
        })
        
        async def generate_stream():
            full_response = ""
            try:
                # Make streaming API call
                stream = await async_openai_client.chat.completions.create(
                    model=model,
                    messages=conversations[conversation_id],
                    temperature=temperature,
                    max_tokens=settings.max_tokens,
                    stream=True
                )
                
                async for chunk in stream:
                    if chunk.choices[0].delta.content is not None:
                        content = chunk.choices[0].delta.content
                        full_response += content
                        yield f"data: {json.dumps({'content': content, 'conversation_id': conversation_id})}\n\n"
                
                # Add complete response to conversation
                conversations[conversation_id].append({
                    "role": "assistant",
                    "content": full_response
                })
                
                # Send completion signal
                yield f"data: {json.dumps({'done': True, 'conversation_id': conversation_id})}\n\n"
                
            except Exception as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"
        
        return StreamingResponse(
            generate_stream(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no"
            }
        )
        
    except Exception as e:
        logger.error(f"Streaming chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat/conversation", tags=["chat"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def conversation_completion(
    request: Request,
    conv_request: ConversationRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Multi-turn conversation completion"""
    start_time = time.time()
    
    try:
        # Use provided values or defaults
        model = conv_request.model or settings.openai_model
        temperature = conv_request.temperature or settings.temperature
        max_tokens = conv_request.max_tokens or settings.max_tokens
        
        # Estimate cost and check budget
        total_text = " ".join([msg["content"] for msg in conv_request.messages])
        estimated_tokens = count_tokens(total_text, model) + max_tokens
        estimated_cost = calculate_cost(estimated_tokens, model)
        check_daily_budget(client_ip, estimated_cost)
        
        # Make API call
        response = openai_client.chat.completions.create(
            model=model,
            messages=conv_request.messages,
            temperature=temperature,
            max_tokens=max_tokens
        )
        
        # Extract response
        assistant_message = response.choices[0].message.content
        
        # Calculate metrics
        tokens_used = response.usage.total_tokens
        cost = calculate_cost(tokens_used, model)
        processing_time = time.time() - start_time
        
        # Update usage stats in background
        background_tasks.add_task(
            update_usage_stats,
            client_ip,
            tokens_used,
            cost,
            processing_time
        )
        
        logger.info(f"Conversation completion: {tokens_used} tokens, ${cost:.4f}, {processing_time:.2f}s")
        
        return {
            "response": assistant_message,
            "tokens_used": tokens_used,
            "cost": cost,
            "model": model,
            "processing_time": processing_time
        }
        
    except Exception as e:
        logger.error(f"Conversation completion error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chat/stats", response_model=UsageStats, tags=["stats"])
async def get_usage_stats(client_ip: str = Depends(get_client_ip)):
    """Get usage statistics for current client"""
    if client_ip not in usage_stats:
        return UsageStats(
            total_requests=0,
            total_tokens=0,
            total_cost=0.0,
            conversations=0,
            average_tokens_per_request=0.0,
            average_cost_per_request=0.0
        )
    
    stats = usage_stats[client_ip]
    return UsageStats(
        total_requests=stats["total_requests"],
        total_tokens=stats["total_tokens"],
        total_cost=stats["total_cost"],
        conversations=len(stats["conversations"]),
        average_tokens_per_request=stats["total_tokens"] / max(1, stats["total_requests"]),
        average_cost_per_request=stats["total_cost"] / max(1, stats["total_requests"])
    )

@app.get("/chat/conversations", tags=["conversations"])
async def list_conversations(client_ip: str = Depends(get_client_ip)):
    """List all conversations for current client"""
    if client_ip not in usage_stats:
        return {"conversations": []}
    
    user_conversations = usage_stats[client_ip]["conversations"]
    return {
        "conversations": [
            {
                "id": conv_id,
                "messages": len(conversations.get(conv_id, [])),
                "created": "unknown"  # Add timestamp tracking in production
            }
            for conv_id in user_conversations
        ]
    }

@app.get("/chat/conversations/{conversation_id}", tags=["conversations"])
async def get_conversation(conversation_id: str):
    """Get specific conversation history"""
    if conversation_id not in conversations:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    return {
        "conversation_id": conversation_id,
        "messages": conversations[conversation_id]
    }

@app.delete("/chat/conversations/{conversation_id}", tags=["conversations"])
async def delete_conversation(conversation_id: str):
    """Delete specific conversation"""
    if conversation_id not in conversations:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    del conversations[conversation_id]
    
    # Remove from user stats
    for user_stats in usage_stats.values():
        if conversation_id in user_stats["conversations"]:
            user_stats["conversations"].remove(conversation_id)
    
    return {"message": "Conversation deleted successfully"}

@app.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint"""
    try:
        # Test OpenAI connection
        test_response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": "test"}],
            max_tokens=1
        )
        
        return {
            "status": "healthy",
            "openai": "connected",
            "model": settings.openai_model,
            "conversations": len(conversations),
            "total_users": len(usage_stats)
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

# Run with: uvicorn example-chat-api:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")