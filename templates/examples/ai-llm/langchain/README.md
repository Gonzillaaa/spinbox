# LangChain Framework Examples

This directory contains examples for using LangChain, a framework for developing applications powered by language models.

## Prerequisites

1. Install the required dependencies:
```bash
pip install langchain langchain-openai langchain-anthropic langchain-community python-dotenv
```

2. Set up your environment variables:
```bash
# Copy the .env.example file and add your API keys
cp .env.example .env
# Edit .env and add your API keys
```

3. Get API keys from the respective providers:
   - OpenAI: [OpenAI API Keys](https://platform.openai.com/api-keys)
   - Anthropic: [Anthropic Console](https://console.anthropic.com/)

## Available Examples

### 1. `example-basic-chain.py` - Basic LangChain Usage
- Simple LLM chain creation
- Prompt templates and basic interactions
- Error handling and configuration

### 2. `example-rag-chain.py` - RAG (Retrieval-Augmented Generation)
- Document loading and vector storage
- Semantic search and retrieval
- Question-answering over documents

### 3. `example-agent.py` - LangChain Agents
- Tool-using agents with function calling
- Multi-step reasoning and planning
- Integration with external APIs

### 4. `example-memory.py` - Conversation Memory
- Persistent conversation history
- Different memory types and strategies
- Context management

## Usage

### Basic Chain Example
```bash
# Run the basic chain example
python example-basic-chain.py
```

### RAG System Example
```bash
# Create a documents directory and add some text files
mkdir documents
echo "LangChain is a framework for developing applications powered by language models." > documents/intro.txt

# Run the RAG example
python example-rag-chain.py
```

### Agent Example
```bash
# Run the agent example
python example-agent.py
```

### Memory Example
```bash
# Run the memory example
python example-memory.py
```

## Environment Variables

```bash
# Required (choose one or more)
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional
LANGCHAIN_MODEL=gpt-3.5-turbo
LANGCHAIN_TEMPERATURE=0.7
LANGCHAIN_MAX_TOKENS=1024
LANGCHAIN_VERBOSE=true
```

## Integration with FastAPI

These examples can be integrated into FastAPI applications:

```python
from fastapi import FastAPI, HTTPException
from langchain.llms import OpenAI
from langchain.chains import ConversationChain
from langchain.memory import ConversationBufferMemory
import os

app = FastAPI()

# Initialize LangChain components
llm = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
memory = ConversationBufferMemory()
conversation = ConversationChain(llm=llm, memory=memory)

@app.post("/chat")
async def chat(message: str):
    try:
        response = conversation.predict(input=message)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/rag-query")
async def rag_query(query: str):
    # RAG implementation would go here
    pass
```

## Best Practices

1. **Model Selection**: Choose the right model for your use case
2. **Memory Management**: Use appropriate memory types for your application
3. **Error Handling**: Implement robust error handling for API failures
4. **Cost Optimization**: Monitor token usage and implement caching
5. **Security**: Secure API keys and validate inputs
6. **Performance**: Use async operations where possible

## Common Use Cases

- **Chatbots**: Conversational AI with memory
- **Document Q&A**: RAG systems for knowledge bases
- **Content Generation**: Automated content creation
- **Code Analysis**: Code review and documentation
- **Data Analysis**: Natural language data queries

## Documentation

- [LangChain Documentation](https://python.langchain.com/)
- [LangChain Cookbook](https://python.langchain.com/docs/expression_language/cookbook/)
- [LangChain Community](https://python.langchain.com/docs/integrations/platforms/)
- [RAG Tutorial](https://python.langchain.com/docs/use_cases/question_answering/)