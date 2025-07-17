# AI/LLM Integration Examples

Production-ready examples for integrating AI and LLM providers with your applications.

## Overview

This directory contains examples for major AI/LLM providers and frameworks:
- **OpenAI**: GPT models, embeddings, function calling
- **Anthropic**: Claude models, constitutional AI
- **LangChain**: RAG pipelines, agents, chains
- **LlamaIndex**: Query engines, document indexing

## Quick Start

### 1. Choose Your Provider
Each provider has its own directory with specific examples and setup instructions.

### 2. Set Up API Keys
Most examples require API keys from the respective providers:
```bash
# OpenAI
export OPENAI_API_KEY="your-openai-key"

# Anthropic
export ANTHROPIC_API_KEY="your-anthropic-key"

# For .env files
cp .env.example .env
# Edit .env with your API keys
```

### 3. Install Dependencies
Each provider directory has specific requirements:
```bash
# OpenAI
pip install openai python-dotenv

# Anthropic
pip install anthropic python-dotenv

# LangChain
pip install langchain openai chromadb

# LlamaIndex
pip install llama-index
```

## Provider Overview

### OpenAI (`openai/`)
- **Chat Completion**: GPT-4, GPT-3.5-turbo integration
- **Embeddings**: Text embeddings for similarity search
- **Function Calling**: Tool use and structured outputs
- **Streaming**: Real-time response streaming
- **Vision**: Image analysis with GPT-4V

### Anthropic (`anthropic/`)
- **Claude Chat**: Claude-3 Sonnet, Haiku, Opus
- **Constitutional AI**: Safe AI patterns
- **Tool Use**: Function calling with Claude
- **Long Context**: Large document processing

### LangChain (`langchain/`)
- **RAG Pipeline**: Retrieval-Augmented Generation
- **Agents**: Tool-using AI agents
- **Chains**: Multi-step reasoning
- **Memory**: Conversation memory
- **Document Loaders**: Various document types

### LlamaIndex (`llamaindex/`)
- **Query Engines**: Document question answering
- **Chat Engines**: Conversational interfaces
- **Indexing**: Document processing and storage
- **Multi-Modal**: Text and image processing

## Common Patterns

### Environment Configuration
```python
import os
from dotenv import load_dotenv

load_dotenv()

# API keys
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")

# Model configuration
MODEL_NAME = os.getenv("MODEL_NAME", "gpt-4")
TEMPERATURE = float(os.getenv("TEMPERATURE", "0.7"))
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "1000"))
```

### Error Handling
```python
try:
    response = client.chat.completions.create(...)
    return response.choices[0].message.content
except Exception as e:
    logger.error(f"AI API error: {e}")
    return {"error": "AI service unavailable", "details": str(e)}
```

### Cost Tracking
```python
def calculate_cost(tokens_used: int, model: str = "gpt-4") -> float:
    """Calculate approximate cost based on token usage"""
    pricing = {
        "gpt-4": 0.03,  # per 1k tokens
        "gpt-3.5-turbo": 0.002,
        "claude-3-sonnet": 0.015
    }
    return (tokens_used / 1000) * pricing.get(model, 0.03)
```

### Response Streaming
```python
async def stream_response(messages):
    """Stream AI response in chunks"""
    stream = await client.chat.completions.create(
        model="gpt-4",
        messages=messages,
        stream=True
    )
    
    async for chunk in stream:
        if chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content
```

## Security Best Practices

### API Key Management
- **Never commit API keys**: Use environment variables
- **Rotate keys regularly**: Generate new keys periodically
- **Use different keys**: Development vs production environments
- **Monitor usage**: Track API usage and costs

### Input Validation
```python
def validate_input(user_input: str) -> str:
    """Validate and sanitize user input"""
    # Remove potential injection attempts
    sanitized = user_input.strip()
    
    # Length limits
    if len(sanitized) > 10000:
        raise ValueError("Input too long")
    
    # Content filtering
    if contains_harmful_content(sanitized):
        raise ValueError("Content not allowed")
    
    return sanitized
```

### Rate Limiting
```python
import time
from functools import wraps

def rate_limit(calls_per_minute: int = 60):
    """Rate limiting decorator"""
    def decorator(func):
        last_called = [0.0]
        
        @wraps(func)
        def wrapper(*args, **kwargs):
            min_interval = 60.0 / calls_per_minute
            elapsed = time.time() - last_called[0]
            
            if elapsed < min_interval:
                time.sleep(min_interval - elapsed)
            
            last_called[0] = time.time()
            return func(*args, **kwargs)
        
        return wrapper
    return decorator
```

## Performance Optimization

### Caching
```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=128)
def cached_embedding(text: str) -> list:
    """Cache embeddings for frequently used text"""
    return client.embeddings.create(input=text, model="text-embedding-ada-002")

def cache_key(text: str) -> str:
    """Generate cache key for text"""
    return hashlib.md5(text.encode()).hexdigest()
```

### Batch Processing
```python
def batch_process_texts(texts: List[str], batch_size: int = 10):
    """Process texts in batches to optimize API calls"""
    results = []
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        batch_results = client.embeddings.create(
            input=batch,
            model="text-embedding-ada-002"
        )
        results.extend(batch_results.data)
    
    return results
```

## Cost Management

### Token Estimation
```python
import tiktoken

def estimate_tokens(text: str, model: str = "gpt-4") -> int:
    """Estimate token count for text"""
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

def estimate_cost(prompt: str, response: str, model: str = "gpt-4") -> float:
    """Estimate cost for prompt and response"""
    total_tokens = estimate_tokens(prompt, model) + estimate_tokens(response, model)
    return calculate_cost(total_tokens, model)
```

### Usage Monitoring
```python
import logging

class UsageTracker:
    def __init__(self):
        self.total_tokens = 0
        self.total_cost = 0.0
        self.request_count = 0
    
    def track_request(self, tokens: int, model: str):
        self.total_tokens += tokens
        self.total_cost += calculate_cost(tokens, model)
        self.request_count += 1
        
        logging.info(f"Request #{self.request_count}: {tokens} tokens, "
                    f"Total cost: ${self.total_cost:.4f}")
```

## Testing

### Mock Testing
```python
import unittest
from unittest.mock import Mock, patch

class TestAIIntegration(unittest.TestCase):
    @patch('openai.OpenAI')
    def test_chat_completion(self, mock_client):
        # Mock response
        mock_response = Mock()
        mock_response.choices[0].message.content = "Test response"
        mock_client.return_value.chat.completions.create.return_value = mock_response
        
        # Test your function
        result = your_ai_function("test input")
        self.assertEqual(result, "Test response")
```

### Integration Testing
```python
def test_with_real_api():
    """Test with real API (use in CI/CD with test keys)"""
    if not os.getenv("OPENAI_API_KEY"):
        unittest.skip("No API key provided")
    
    client = OpenAI()
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": "Hello"}],
        max_tokens=50
    )
    
    assert response.choices[0].message.content
```

## Next Steps

1. **Choose a provider**: Start with OpenAI for general use
2. **Set up authentication**: Configure API keys securely
3. **Try basic examples**: Start with simple chat completion
4. **Explore combinations**: Check `combinations/` for FastAPI integration
5. **Build applications**: Use patterns from `full-stack/` examples

## Getting Help

- **Provider Documentation**: Check official API docs
- **Community**: Join Discord/forums for each provider
- **Stack Overflow**: Search for specific integration issues
- **GitHub Issues**: Report bugs in example code

---

*Remember to monitor your API usage and costs, especially in production environments.*