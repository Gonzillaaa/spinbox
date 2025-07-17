# FastAPI + OpenAI Integration

Complete examples for building AI-powered APIs using FastAPI and OpenAI.

## Overview

This combination demonstrates how to create production-ready AI-powered APIs using:
- **FastAPI**: Modern, fast web framework for building APIs
- **OpenAI**: GPT models for chat completion, embeddings, and function calling

## Prerequisites

1. **API Keys**: OpenAI API key from https://platform.openai.com/
2. **Dependencies**:
   ```bash
   pip install fastapi uvicorn openai python-dotenv pydantic tiktoken
   ```

## Environment Setup

Create `.env` file:
```env
# OpenAI Configuration
OPENAI_API_KEY=your-openai-key-here
OPENAI_MODEL=gpt-4
OPENAI_TEMPERATURE=0.7
OPENAI_MAX_TOKENS=1000

# FastAPI Configuration
DEBUG=True
SECRET_KEY=your-secret-key-here

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
DAILY_BUDGET=10.00
```

## Examples Included

### `example-chat-api.py`
RESTful chat API with OpenAI integration.

**Features:**
- Chat completion endpoints
- Conversation history management
- Token usage tracking
- Cost monitoring
- Error handling
- Rate limiting

**Endpoints:**
- `POST /chat` - Single chat completion
- `POST /chat/stream` - Streaming chat responses
- `POST /chat/conversation` - Multi-turn conversations
- `GET /chat/stats` - Usage statistics

### `example-embeddings-api.py`
Embeddings API for semantic search and similarity.

**Features:**
- Text embedding generation
- Similarity search
- Batch processing
- Caching for performance
- Vector operations

**Endpoints:**
- `POST /embeddings` - Generate embeddings
- `POST /embeddings/batch` - Batch embedding generation
- `POST /similarity` - Calculate text similarity
- `POST /search` - Semantic search

### `example-function-calling-api.py`
Function calling API with tool integration.

**Features:**
- Tool definition and execution
- Structured outputs
- Multiple function support
- Error handling
- Result validation

**Endpoints:**
- `POST /tools/call` - Execute function calls
- `GET /tools/list` - List available tools
- `POST /tools/register` - Register new tools

## Usage Examples

### 1. Basic Chat Completion
```bash
curl -X POST "http://localhost:8000/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, how are you?"}'
```

### 2. Streaming Chat
```bash
curl -X POST "http://localhost:8000/chat/stream" \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me a story"}' \
  --no-buffer
```

### 3. Generate Embeddings
```bash
curl -X POST "http://localhost:8000/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}'
```

### 4. Semantic Search
```bash
curl -X POST "http://localhost:8000/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "artificial intelligence",
    "documents": [
      "Machine learning is a subset of AI",
      "Python is a programming language",
      "Deep learning uses neural networks"
    ]
  }'
```

### 5. Function Calling
```bash
curl -X POST "http://localhost:8000/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is the weather like?",
    "tools": ["get_weather"]
  }'
```

## Architecture Patterns

### 1. Service Layer Pattern
```python
# services/openai_service.py
class OpenAIService:
    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
    
    async def chat_completion(self, message: str) -> dict:
        # Implementation
        pass
```

### 2. Dependency Injection
```python
# dependencies.py
def get_openai_service():
    return OpenAIService()

# API endpoint
@app.post("/chat")
async def chat(
    request: ChatRequest,
    service: OpenAIService = Depends(get_openai_service)
):
    return await service.chat_completion(request.message)
```

### 3. Error Handling
```python
@app.exception_handler(OpenAIError)
async def openai_error_handler(request: Request, exc: OpenAIError):
    return JSONResponse(
        status_code=503,
        content={"error": "AI service unavailable", "details": str(exc)}
    )
```

### 4. Rate Limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/chat")
@limiter.limit("10/minute")
async def chat(request: Request, message: ChatRequest):
    # Implementation
    pass
```

## Security Considerations

### 1. API Key Security
- Store API keys in environment variables
- Use different keys for development/production
- Monitor API key usage
- Rotate keys regularly

### 2. Input Validation
```python
from pydantic import BaseModel, validator

class ChatRequest(BaseModel):
    message: str
    
    @validator('message')
    def validate_message(cls, v):
        if len(v) > 10000:
            raise ValueError('Message too long')
        return v.strip()
```

### 3. Rate Limiting
```python
# Implement per-user rate limiting
@app.post("/chat")
@limiter.limit("60/minute")
async def chat(request: Request, message: ChatRequest):
    pass
```

### 4. Content Filtering
```python
def filter_content(text: str) -> str:
    # Implement content filtering
    if contains_harmful_content(text):
        raise HTTPException(400, "Content not allowed")
    return text
```

## Performance Optimization

### 1. Async Operations
```python
import asyncio
from openai import AsyncOpenAI

async def process_multiple_requests(requests):
    client = AsyncOpenAI()
    tasks = [client.chat.completions.create(...) for req in requests]
    return await asyncio.gather(*tasks)
```

### 2. Response Caching
```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=128)
def cached_completion(message_hash: str):
    # Cache responses for identical requests
    pass
```

### 3. Connection Pooling
```python
import httpx
from openai import OpenAI

# Use persistent HTTP client
http_client = httpx.AsyncClient(timeout=60.0)
client = OpenAI(http_client=http_client)
```

## Cost Management

### 1. Token Counting
```python
import tiktoken

def count_tokens(text: str, model: str = "gpt-4") -> int:
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))
```

### 2. Usage Tracking
```python
class UsageTracker:
    def __init__(self):
        self.total_tokens = 0
        self.total_cost = 0.0
    
    def track_usage(self, tokens: int, model: str):
        cost = calculate_cost(tokens, model)
        self.total_tokens += tokens
        self.total_cost += cost
```

### 3. Budget Limits
```python
async def check_budget(user_id: str, estimated_cost: float):
    current_usage = get_user_usage(user_id)
    if current_usage + estimated_cost > DAILY_BUDGET:
        raise HTTPException(402, "Daily budget exceeded")
```

## Testing

### 1. Unit Tests
```python
import pytest
from unittest.mock import Mock, patch

@patch('openai.OpenAI')
def test_chat_completion(mock_client):
    mock_response = Mock()
    mock_response.choices[0].message.content = "Test response"
    mock_client.return_value.chat.completions.create.return_value = mock_response
    
    # Test your function
    result = chat_completion("test message")
    assert result == "Test response"
```

### 2. Integration Tests
```python
from fastapi.testclient import TestClient

def test_chat_endpoint():
    client = TestClient(app)
    response = client.post("/chat", json={"message": "Hello"})
    assert response.status_code == 200
    assert "response" in response.json()
```

### 3. Load Testing
```python
import asyncio
import aiohttp

async def load_test():
    async with aiohttp.ClientSession() as session:
        tasks = []
        for i in range(100):
            task = session.post(
                "http://localhost:8000/chat",
                json={"message": f"Test message {i}"}
            )
            tasks.append(task)
        
        responses = await asyncio.gather(*tasks)
        return responses
```

## Monitoring and Logging

### 1. Request Logging
```python
import logging
from fastapi import Request

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(f"Path: {request.url.path} - Time: {process_time:.3f}s")
    return response
```

### 2. Usage Metrics
```python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter('requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('request_duration_seconds', 'Request duration')

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path).inc()
    REQUEST_DURATION.observe(duration)
    
    return response
```

## Deployment

### 1. Docker Configuration
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Environment Variables
```bash
# Production environment
OPENAI_API_KEY=prod-key-here
OPENAI_MODEL=gpt-4
DEBUG=False
SECRET_KEY=production-secret-key
RATE_LIMIT_PER_MINUTE=100
DAILY_BUDGET=100.00
```

### 3. Health Checks
```python
@app.get("/health")
async def health_check():
    try:
        # Test OpenAI connection
        await openai_service.test_connection()
        return {"status": "healthy", "openai": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

## Common Issues and Solutions

### 1. Rate Limiting Errors
**Problem**: `RateLimitError` from OpenAI
**Solution**: Implement exponential backoff and request queuing

### 2. Token Limit Errors
**Problem**: `InvalidRequestError` - context length exceeded
**Solution**: Truncate input or use conversation summarization

### 3. High Latency
**Problem**: Slow API responses
**Solution**: Use async operations, connection pooling, and caching

### 4. Memory Usage
**Problem**: High memory consumption
**Solution**: Implement response streaming and cleanup

## Next Steps

1. **Start with basic chat**: Try `example-chat-api.py`
2. **Add embeddings**: Implement semantic search with `example-embeddings-api.py`
3. **Function calling**: Add tool integration with `example-function-calling-api.py`
4. **Scale up**: Add Redis caching, database integration
5. **Deploy**: Use Docker and cloud services

## Resources

- **OpenAI API Documentation**: https://platform.openai.com/docs/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Example Applications**: Check `combinations/full-stack/` for complete apps