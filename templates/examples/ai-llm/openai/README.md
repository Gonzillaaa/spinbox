# OpenAI Integration Examples

Production-ready examples for OpenAI GPT models, embeddings, and function calling.

## Prerequisites

1. **OpenAI API Key**: Get your API key from https://platform.openai.com/
2. **Python Dependencies**:
   ```bash
   pip install openai python-dotenv tiktoken
   ```

## Environment Setup

Create `.env` file:
```env
# OpenAI Configuration
OPENAI_API_KEY=your-api-key-here
OPENAI_MODEL=gpt-4
OPENAI_TEMPERATURE=0.7
OPENAI_MAX_TOKENS=1000

# Cost Management
OPENAI_RATE_LIMIT=60  # requests per minute
OPENAI_DAILY_BUDGET=10.00  # dollars
```

## Examples Included

### `example-chat.py`
Basic chat completion with GPT-4.

**Features:**
- Simple chat interface
- Token usage tracking
- Cost estimation
- Error handling
- Interactive CLI

**Usage:**
```bash
python example-chat.py
```

### `example-embeddings.py`
Text embeddings for similarity search.

**Features:**
- Text embedding generation
- Similarity calculation
- Batch processing
- Caching for efficiency
- Vector operations

**Usage:**
```bash
python example-embeddings.py
```

### `example-function-calling.py`
Function calling and tool use.

**Features:**
- Tool definition and execution
- Structured outputs
- Error handling for tool failures
- Multiple function support
- Result validation

**Usage:**
```bash
python example-function-calling.py
```

### `example-streaming.py`
Real-time response streaming.

**Features:**
- Streaming chat responses
- Chunk processing
- Error handling during streaming
- Progress indicators
- Stop sequences

**Usage:**
```bash
python example-streaming.py
```

## API Models

### Chat Models
- **GPT-4**: Most capable, higher cost
- **GPT-4-turbo**: Optimized for speed and cost
- **GPT-3.5-turbo**: Fast and cost-effective

### Embedding Models
- **text-embedding-ada-002**: General-purpose embeddings
- **text-embedding-3-small**: Smaller, faster embeddings
- **text-embedding-3-large**: Highest quality embeddings

## Cost Management

### Current Pricing (approximate)
- **GPT-4**: $0.03 per 1K tokens
- **GPT-3.5-turbo**: $0.002 per 1K tokens
- **Embeddings**: $0.0001 per 1K tokens

### Cost Optimization Tips
1. **Use GPT-3.5-turbo** for simple tasks
2. **Limit max_tokens** to control costs
3. **Cache responses** for repeated queries
4. **Use embeddings** for search instead of multiple completions
5. **Batch process** multiple requests

## Common Use Cases

### 1. Chatbots and Conversational AI
```python
def create_chatbot(system_prompt: str):
    messages = [{"role": "system", "content": system_prompt}]
    
    while True:
        user_input = input("You: ")
        messages.append({"role": "user", "content": user_input})
        
        response = client.chat.completions.create(
            model="gpt-4",
            messages=messages,
            max_tokens=1000
        )
        
        assistant_message = response.choices[0].message.content
        messages.append({"role": "assistant", "content": assistant_message})
        print(f"Assistant: {assistant_message}")
```

### 2. Content Generation
```python
def generate_content(prompt: str, style: str = "professional"):
    system_prompt = f"Write in a {style} style."
    
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7
    )
    
    return response.choices[0].message.content
```

### 3. Code Generation
```python
def generate_code(description: str, language: str = "python"):
    prompt = f"Generate {language} code for: {description}"
    
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": f"You are a {language} expert. Generate clean, well-commented code."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.2
    )
    
    return response.choices[0].message.content
```

### 4. Document Analysis
```python
def analyze_document(document_text: str, question: str):
    prompt = f"Document: {document_text}\n\nQuestion: {question}"
    
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "Analyze the document and answer questions accurately."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=500
    )
    
    return response.choices[0].message.content
```

### 5. Semantic Search
```python
def semantic_search(query: str, documents: List[str], top_k: int = 5):
    # Get query embedding
    query_embedding = client.embeddings.create(
        input=query,
        model="text-embedding-ada-002"
    ).data[0].embedding
    
    # Get document embeddings
    doc_embeddings = []
    for doc in documents:
        embedding = client.embeddings.create(
            input=doc,
            model="text-embedding-ada-002"
        ).data[0].embedding
        doc_embeddings.append(embedding)
    
    # Calculate similarities
    similarities = []
    for i, doc_embedding in enumerate(doc_embeddings):
        similarity = cosine_similarity(query_embedding, doc_embedding)
        similarities.append((i, similarity))
    
    # Return top results
    similarities.sort(key=lambda x: x[1], reverse=True)
    return [(documents[i], score) for i, score in similarities[:top_k]]
```

## Error Handling

### Common Errors
- **Rate Limiting**: Too many requests
- **Token Limit**: Input too long
- **API Key Issues**: Invalid or expired key
- **Model Availability**: Model not available

### Error Handling Pattern
```python
import openai
from openai import OpenAI
import time

def robust_api_call(messages, max_retries=3):
    client = OpenAI()
    
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="gpt-4",
                messages=messages,
                max_tokens=1000
            )
            return response.choices[0].message.content
            
        except openai.RateLimitError:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                time.sleep(wait_time)
                continue
            else:
                raise
                
        except openai.APIError as e:
            print(f"API Error: {e}")
            return None
            
        except Exception as e:
            print(f"Unexpected error: {e}")
            return None
```

## Performance Optimization

### 1. Connection Pooling
```python
import httpx
from openai import OpenAI

# Use persistent HTTP client
http_client = httpx.Client(timeout=60.0)
client = OpenAI(http_client=http_client)
```

### 2. Async Processing
```python
import asyncio
from openai import AsyncOpenAI

async def async_completion(messages):
    client = AsyncOpenAI()
    response = await client.chat.completions.create(
        model="gpt-4",
        messages=messages
    )
    return response.choices[0].message.content

async def process_multiple_requests(message_lists):
    tasks = [async_completion(messages) for messages in message_lists]
    results = await asyncio.gather(*tasks)
    return results
```

### 3. Response Caching
```python
import hashlib
import json
from functools import lru_cache

@lru_cache(maxsize=128)
def cached_completion(messages_hash: str, model: str):
    # This would be called with a hash of the messages
    # to avoid mutable arguments in lru_cache
    return client.chat.completions.create(
        model=model,
        messages=json.loads(messages_hash)
    )

def get_cached_response(messages, model="gpt-4"):
    messages_str = json.dumps(messages, sort_keys=True)
    messages_hash = hashlib.md5(messages_str.encode()).hexdigest()
    return cached_completion(messages_hash, model)
```

## Testing

### Unit Tests
```python
import unittest
from unittest.mock import Mock, patch

class TestOpenAIIntegration(unittest.TestCase):
    @patch('openai.OpenAI')
    def test_chat_completion(self, mock_client):
        # Mock response
        mock_response = Mock()
        mock_response.choices[0].message.content = "Test response"
        mock_client.return_value.chat.completions.create.return_value = mock_response
        
        # Test your function
        result = your_chat_function("test input")
        self.assertEqual(result, "Test response")
```

### Integration Tests
```python
def test_real_api():
    """Test with real API using test credentials"""
    if not os.getenv("OPENAI_API_KEY"):
        unittest.skip("No API key provided")
    
    client = OpenAI()
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": "Say 'test'"}],
        max_tokens=10
    )
    
    assert "test" in response.choices[0].message.content.lower()
```

## Security Considerations

1. **API Key Security**: Never commit keys to version control
2. **Input Validation**: Sanitize user inputs
3. **Rate Limiting**: Implement client-side rate limiting
4. **Content Filtering**: Filter inappropriate content
5. **Audit Logging**: Log all API calls for security monitoring

## Troubleshooting

### Common Issues

**Authentication Error**:
```
openai.AuthenticationError: Invalid API key
```
- Check your API key is set correctly
- Verify the key hasn't expired
- Ensure you have sufficient credits

**Rate Limit Error**:
```
openai.RateLimitError: Rate limit exceeded
```
- Implement exponential backoff
- Reduce request frequency
- Consider upgrading your plan

**Token Limit Error**:
```
openai.BadRequestError: Maximum context length exceeded
```
- Reduce input length
- Increase max_tokens parameter
- Split large inputs into chunks

**Network Errors**:
```
openai.APIConnectionError: Connection error
```
- Check internet connection
- Verify firewall settings
- Try again with retry logic

## Next Steps

1. **Try basic examples**: Start with `example-chat.py`
2. **Explore embeddings**: Use `example-embeddings.py` for search
3. **Function calling**: Check `example-function-calling.py`
4. **Streaming responses**: Test `example-streaming.py`
5. **FastAPI integration**: See `combinations/fastapi-openai/`

## Additional Resources

- **OpenAI Cookbook**: https://cookbook.openai.com/
- **API Documentation**: https://platform.openai.com/docs/
- **Community Forum**: https://community.openai.com/
- **Usage Dashboard**: https://platform.openai.com/usage