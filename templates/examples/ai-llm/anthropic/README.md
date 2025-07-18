# Anthropic Claude Integration Examples

This directory contains examples for integrating Anthropic's Claude API into your applications.

## Prerequisites

1. Install the required dependencies:
```bash
pip install anthropic python-dotenv
```

2. Set up your environment variables:
```bash
# Copy the .env.example file and add your API key
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY
```

3. Get your API key from [Anthropic Console](https://console.anthropic.com/)

## Available Examples

### 1. `example-chat.py` - Basic Chat Interface
- Simple chat completion using Claude
- Demonstrates basic conversation flow
- Error handling and response formatting

### 2. `example-function-calling.py` - Function Calling
- Advanced function calling capabilities
- Tool usage and structured outputs
- Integration with external APIs

### 3. `example-chat.js` - JavaScript Chat Interface
- Node.js implementation of Claude chat
- Browser-compatible examples
- TypeScript support

## Usage

### Python Examples
```bash
# Run the chat example
python example-chat.py

# Run the function calling example
python example-function-calling.py
```

### JavaScript Examples
```bash
# Install dependencies
npm install @anthropic-ai/sdk dotenv

# Run the chat example
node example-chat.js
```

## Environment Variables

```bash
# Required
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional
ANTHROPIC_MODEL=claude-3-sonnet-20240229
ANTHROPIC_MAX_TOKENS=1024
ANTHROPIC_TEMPERATURE=0.7
```

## Integration with FastAPI

These examples can be easily integrated into FastAPI applications:

```python
from fastapi import FastAPI
from anthropic import Anthropic
import os

app = FastAPI()
client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

@app.post("/chat")
async def chat(message: str):
    response = client.messages.create(
        model="claude-3-sonnet-20240229",
        max_tokens=1024,
        messages=[{"role": "user", "content": message}]
    )
    return {"response": response.content[0].text}
```

## Best Practices

1. **Error Handling**: Always handle API errors gracefully
2. **Rate Limiting**: Implement proper rate limiting for production use
3. **Token Management**: Monitor token usage and costs
4. **Security**: Never expose API keys in client-side code
5. **Caching**: Consider caching responses for frequently asked questions

## Documentation

- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference/getting-started)
- [Claude Model Information](https://docs.anthropic.com/claude/docs/models-overview)
- [Function Calling Guide](https://docs.anthropic.com/claude/docs/functions-external-tools)