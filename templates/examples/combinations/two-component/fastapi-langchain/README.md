# FastAPI + LangChain Integration

Complete examples for building AI-powered applications using FastAPI and LangChain for advanced LLM workflows.

## Overview

This combination demonstrates how to create sophisticated AI applications using:
- **FastAPI**: Modern, fast web framework for building APIs
- **LangChain**: Framework for developing applications with large language models
- **Vector Databases**: For semantic search and retrieval
- **Memory Management**: For conversational AI applications
- **Agent Workflows**: For complex AI task automation

## Prerequisites

1. **API Keys**: OpenAI, Anthropic, or other LLM provider API keys
2. **Dependencies**:
   ```bash
   pip install fastapi uvicorn langchain openai anthropic chromadb python-dotenv
   ```

## Environment Setup

Create `.env` file:
```env
# LLM Provider Configuration
OPENAI_API_KEY=your-openai-key-here
ANTHROPIC_API_KEY=your-anthropic-key-here
OPENAI_MODEL=gpt-4

# Vector Database
CHROMA_PERSIST_DIR=./chroma_db

# FastAPI Configuration
DEBUG=True
SECRET_KEY=your-secret-key-here

# LangChain Configuration
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=your-langchain-key-here
LANGCHAIN_PROJECT=your-project-name
```

## Examples Included

### `example-chat-with-memory.py`
Conversational AI with memory management.

**Features:**
- Chat with memory persistence
- Conversation history management
- Context-aware responses
- Session management
- Memory summarization

**Endpoints:**
- `POST /chat/message` - Send message to AI
- `GET /chat/history` - Get conversation history
- `POST /chat/clear` - Clear conversation memory
- `GET /chat/sessions` - List chat sessions

### `example-rag-system.py`
Retrieval-Augmented Generation (RAG) system.

**Features:**
- Document ingestion and indexing
- Semantic search
- Context-based Q&A
- Document chunking
- Vector similarity search

**Endpoints:**
- `POST /rag/upload` - Upload documents
- `POST /rag/query` - Query documents
- `GET /rag/documents` - List documents
- `DELETE /rag/documents/{id}` - Delete document

### `example-ai-agents.py`
AI agents with tool integration.

**Features:**
- Agent creation and management
- Tool calling capabilities
- Multi-step reasoning
- Task execution
- Agent coordination

**Endpoints:**
- `POST /agents/create` - Create AI agent
- `POST /agents/{id}/execute` - Execute task
- `GET /agents/{id}/status` - Get agent status
- `GET /agents/tools` - List available tools

## Usage Examples

### 1. Chat with Memory
```bash
curl -X POST "http://localhost:8000/chat/message" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, my name is John",
    "session_id": "user_123"
  }'
```

### 2. RAG Document Query
```bash
# Upload document
curl -X POST "http://localhost:8000/rag/upload" \
  -F "file=@document.pdf" \
  -F "title=Important Document"

# Query document
curl -X POST "http://localhost:8000/rag/query" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What are the key points?",
    "top_k": 3
  }'
```

### 3. AI Agent Execution
```bash
curl -X POST "http://localhost:8000/agents/create" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "research_agent",
    "description": "Research and analysis agent",
    "tools": ["web_search", "calculator"]
  }'
```

### 4. Document Processing
```bash
curl -X POST "http://localhost:8000/rag/upload" \
  -F "file=@research_paper.pdf" \
  -F "metadata={\"category\": \"research\", \"author\": \"John Doe\"}"
```

## LangChain Integration Patterns

### 1. Memory Management
```python
from langchain.memory import ConversationBufferWindowMemory
from langchain.memory import ConversationSummaryBufferMemory

class MemoryManager:
    def __init__(self):
        self.memories = {}
    
    def get_memory(self, session_id: str):
        if session_id not in self.memories:
            self.memories[session_id] = ConversationBufferWindowMemory(
                k=10,  # Keep last 10 exchanges
                return_messages=True
            )
        return self.memories[session_id]
    
    def clear_memory(self, session_id: str):
        if session_id in self.memories:
            del self.memories[session_id]
```

### 2. RAG Pipeline
```python
from langchain.vectorstores import Chroma
from langchain.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA

class RAGSystem:
    def __init__(self):
        self.embeddings = OpenAIEmbeddings()
        self.vectorstore = Chroma(
            persist_directory="./chroma_db",
            embedding_function=self.embeddings
        )
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
    
    def add_documents(self, documents):
        chunks = self.text_splitter.split_documents(documents)
        self.vectorstore.add_documents(chunks)
    
    def query(self, question: str, top_k: int = 3):
        retriever = self.vectorstore.as_retriever(search_kwargs={"k": top_k})
        qa_chain = RetrievalQA.from_chain_type(
            llm=self.llm,
            retriever=retriever,
            return_source_documents=True
        )
        return qa_chain({"query": question})
```

### 3. Agent Framework
```python
from langchain.agents import create_openai_functions_agent
from langchain.tools import Tool
from langchain.agents import AgentExecutor

class AgentManager:
    def __init__(self):
        self.agents = {}
        self.tools = self._create_tools()
    
    def _create_tools(self):
        return [
            Tool(
                name="calculator",
                description="Useful for math calculations",
                func=self._calculator
            ),
            Tool(
                name="web_search",
                description="Search the web for information",
                func=self._web_search
            )
        ]
    
    def create_agent(self, name: str, tools: List[str]):
        selected_tools = [tool for tool in self.tools if tool.name in tools]
        
        agent = create_openai_functions_agent(
            llm=self.llm,
            tools=selected_tools,
            prompt=self._get_agent_prompt()
        )
        
        agent_executor = AgentExecutor(
            agent=agent,
            tools=selected_tools,
            verbose=True
        )
        
        self.agents[name] = agent_executor
        return agent_executor
```

## Advanced Features

### 1. Custom Chain Implementation
```python
from langchain.chains.base import Chain
from langchain.schema import BaseMessage

class CustomAnalysisChain(Chain):
    def __init__(self, llm, **kwargs):
        super().__init__(**kwargs)
        self.llm = llm
    
    @property
    def input_keys(self):
        return ["text", "analysis_type"]
    
    @property
    def output_keys(self):
        return ["analysis", "confidence"]
    
    def _call(self, inputs):
        text = inputs["text"]
        analysis_type = inputs["analysis_type"]
        
        prompt = f"Perform {analysis_type} analysis on: {text}"
        result = self.llm(prompt)
        
        return {
            "analysis": result,
            "confidence": 0.8  # Example confidence score
        }
```

### 2. Document Processing Pipeline
```python
from langchain.document_loaders import PyPDFLoader, TextLoader
from langchain.schema import Document

class DocumentProcessor:
    def __init__(self):
        self.loaders = {
            '.pdf': PyPDFLoader,
            '.txt': TextLoader,
        }
    
    def process_file(self, file_path: str, metadata: dict = None):
        ext = os.path.splitext(file_path)[1].lower()
        
        if ext not in self.loaders:
            raise ValueError(f"Unsupported file type: {ext}")
        
        loader = self.loaders[ext](file_path)
        documents = loader.load()
        
        # Add metadata
        if metadata:
            for doc in documents:
                doc.metadata.update(metadata)
        
        return documents
```

### 3. Streaming Responses
```python
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler
from langchain.callbacks.base import BaseCallbackHandler

class StreamingResponseHandler(BaseCallbackHandler):
    def __init__(self):
        self.tokens = []
    
    def on_llm_new_token(self, token: str, **kwargs):
        self.tokens.append(token)
        # Could emit to WebSocket here
    
    def on_llm_end(self, response, **kwargs):
        # Final processing
        pass
```

## Security Considerations

### 1. Input Validation
```python
from pydantic import BaseModel, validator

class ChatRequest(BaseModel):
    message: str
    session_id: str
    
    @validator('message')
    def validate_message(cls, v):
        if len(v) > 10000:
            raise ValueError('Message too long')
        return v
    
    @validator('session_id')
    def validate_session_id(cls, v):
        if not v.strip():
            raise ValueError('Session ID required')
        return v
```

### 2. Rate Limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/chat/message")
@limiter.limit("10/minute")
async def chat_message(request: Request, chat_request: ChatRequest):
    # Implementation
    pass
```

### 3. Cost Management
```python
class CostTracker:
    def __init__(self):
        self.usage = {}
    
    def track_usage(self, user_id: str, tokens: int, cost: float):
        if user_id not in self.usage:
            self.usage[user_id] = {"tokens": 0, "cost": 0.0}
        
        self.usage[user_id]["tokens"] += tokens
        self.usage[user_id]["cost"] += cost
    
    def check_limit(self, user_id: str, daily_limit: float):
        current_cost = self.usage.get(user_id, {}).get("cost", 0.0)
        return current_cost < daily_limit
```

## Performance Optimization

### 1. Caching
```python
from functools import lru_cache
import redis

class CacheManager:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
    
    def get_cached_response(self, key: str):
        return self.redis_client.get(key)
    
    def cache_response(self, key: str, response: str, ttl: int = 3600):
        self.redis_client.setex(key, ttl, response)
```

### 2. Async Processing
```python
from langchain.llms import OpenAI
from langchain.callbacks.manager import CallbackManager

async def async_llm_call(prompt: str):
    llm = OpenAI(
        temperature=0.7,
        callback_manager=CallbackManager([])
    )
    
    # Async call
    result = await llm.agenerate([prompt])
    return result
```

### 3. Connection Pooling
```python
from langchain.llms import OpenAI
import asyncio

class LLMPool:
    def __init__(self, pool_size: int = 5):
        self.pool = asyncio.Queue(maxsize=pool_size)
        self._initialize_pool(pool_size)
    
    async def _initialize_pool(self, size: int):
        for _ in range(size):
            llm = OpenAI(temperature=0.7)
            await self.pool.put(llm)
    
    async def get_llm(self):
        return await self.pool.get()
    
    async def return_llm(self, llm):
        await self.pool.put(llm)
```

## Testing

### 1. Unit Tests
```python
import pytest
from unittest.mock import Mock, patch

@pytest.fixture
def mock_llm():
    llm = Mock()
    llm.return_value = "Test response"
    return llm

def test_chat_message(mock_llm):
    memory_manager = MemoryManager()
    memory = memory_manager.get_memory("test_session")
    
    # Test memory functionality
    memory.save_context({"input": "Hello"}, {"output": "Hi there!"})
    
    messages = memory.chat_memory.messages
    assert len(messages) == 2
    assert messages[0].content == "Hello"
    assert messages[1].content == "Hi there!"
```

### 2. Integration Tests
```python
from fastapi.testclient import TestClient

def test_chat_endpoint():
    client = TestClient(app)
    
    response = client.post("/chat/message", json={
        "message": "Hello",
        "session_id": "test_session"
    })
    
    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert data["session_id"] == "test_session"
```

## Deployment

### 1. Docker Configuration
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Create directories
RUN mkdir -p /app/chroma_db /app/uploads

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Environment Variables
```env
# Production environment
DEBUG=False
SECRET_KEY=production-secret-key
OPENAI_API_KEY=your-production-openai-key
CHROMA_PERSIST_DIR=/app/chroma_db

# Rate limiting
RATE_LIMIT_PER_MINUTE=100
DAILY_COST_LIMIT=50.00

# Monitoring
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=your-langchain-key
```

## Monitoring

### 1. LangSmith Integration
```python
import langsmith

# Configure LangSmith
langsmith.configure(
    api_key=os.getenv("LANGCHAIN_API_KEY"),
    project=os.getenv("LANGCHAIN_PROJECT")
)

# Trace LLM calls
@langsmith.trace
def process_chat_message(message: str, session_id: str):
    # Your chat processing logic
    pass
```

### 2. Custom Metrics
```python
from prometheus_client import Counter, Histogram

# Define metrics
llm_requests = Counter('llm_requests_total', 'Total LLM requests')
llm_duration = Histogram('llm_request_duration_seconds', 'LLM request duration')

@llm_duration.time()
def make_llm_call(prompt: str):
    llm_requests.inc()
    # Make LLM call
    pass
```

## Common Issues and Solutions

### 1. Memory Management
**Problem**: Memory usage grows over time
**Solution**: Implement memory summarization and cleanup

### 2. Rate Limiting
**Problem**: API rate limits exceeded
**Solution**: Implement exponential backoff and request queuing

### 3. Context Length
**Problem**: Context window exceeded
**Solution**: Implement context truncation and summarization

### 4. Vector Store Performance
**Problem**: Slow similarity search
**Solution**: Use appropriate indexing and optimize chunk sizes

## Next Steps

1. **Start with chat memory**: Try `example-chat-with-memory.py`
2. **Build RAG system**: Implement `example-rag-system.py`
3. **Create AI agents**: Use `example-ai-agents.py`
4. **Scale up**: Add monitoring, caching, and optimization
5. **Deploy**: Use Docker and cloud services

## Resources

- **LangChain Documentation**: https://python.langchain.com/docs/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **LangSmith**: https://smith.langchain.com/
- **Vector Databases**: https://www.pinecone.io/learn/vector-database/