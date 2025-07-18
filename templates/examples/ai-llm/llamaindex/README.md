# LlamaIndex Framework Examples

This directory contains examples for using LlamaIndex, a data framework for building LLM applications with private or domain-specific data.

## Prerequisites

1. Install the required dependencies:
```bash
pip install llama-index llama-index-llms-openai llama-index-embeddings-openai python-dotenv
```

2. Set up your environment variables:
```bash
# Copy the .env.example file and add your API key
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY
```

3. Get your API key from [OpenAI](https://platform.openai.com/api-keys)

## Available Examples

### 1. `example-basic-index.py` - Basic Document Indexing
- Simple document loading and indexing
- Basic query engine creation
- Document retrieval and querying

### 2. `example-query-engine.py` - Advanced Query Engine
- Custom query engines with different strategies
- Response synthesis and formatting
- Query optimization techniques

### 3. `example-knowledge-base.py` - Knowledge Base System
- Multi-document knowledge base
- Persistent storage with vector databases
- Advanced retrieval strategies

## Usage

### Basic Index Example
```bash
# Create a documents directory and add some text files
mkdir documents
echo "LlamaIndex is a data framework for LLM applications." > documents/intro.txt

# Run the basic index example
python example-basic-index.py
```

### Query Engine Example
```bash
# Run the query engine example
python example-query-engine.py
```

### Knowledge Base Example
```bash
# Run the knowledge base example
python example-knowledge-base.py
```

## Environment Variables

```bash
# Required
OPENAI_API_KEY=your_openai_api_key_here

# Optional
LLAMAINDEX_MODEL=gpt-3.5-turbo
LLAMAINDEX_TEMPERATURE=0.1
LLAMAINDEX_MAX_TOKENS=1024
LLAMAINDEX_CHUNK_SIZE=1024
LLAMAINDEX_CHUNK_OVERLAP=200
```

## Integration with FastAPI

These examples can be easily integrated into FastAPI applications:

```python
from fastapi import FastAPI, HTTPException
from llama_index import VectorStoreIndex, SimpleDirectoryReader
from llama_index.llms import OpenAI
import os

app = FastAPI()

# Initialize LlamaIndex
llm = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
documents = SimpleDirectoryReader("documents").load_data()
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine(llm=llm)

@app.post("/query")
async def query_documents(query: str):
    try:
        response = query_engine.query(query)
        return {"response": str(response)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy", "documents": len(documents)}
```

## Key Features

### Document Loading
- **SimpleDirectoryReader**: Load documents from directories
- **File Support**: PDF, DOCX, TXT, HTML, and more
- **Web Loading**: URLs and web scraping
- **Database Integration**: SQL, MongoDB, and more

### Indexing Strategies
- **VectorStoreIndex**: Vector-based similarity search
- **ListIndex**: Sequential document processing
- **TreeIndex**: Hierarchical document structure
- **KeywordTableIndex**: Keyword-based retrieval

### Query Engines
- **Retrieval**: Find relevant documents
- **Synthesis**: Generate responses from retrieved content
- **Customization**: Custom prompt templates and response formatting
- **Streaming**: Real-time response generation

### Vector Stores
- **Simple Vector Store**: In-memory storage
- **Chroma**: Open-source vector database
- **Pinecone**: Managed vector database
- **Weaviate**: Vector search engine

## Best Practices

1. **Data Preparation**: Clean and structure your documents
2. **Chunk Size**: Optimize chunk size for your use case
3. **Embedding Model**: Choose appropriate embedding model
4. **Query Optimization**: Use appropriate query strategies
5. **Caching**: Implement caching for frequently accessed data
6. **Error Handling**: Handle API rate limits and failures
7. **Monitoring**: Track query performance and costs

## Common Use Cases

- **Document Q&A**: Question-answering over documents
- **Knowledge Base**: Searchable knowledge repositories
- **Research Assistant**: Academic and research applications
- **Customer Support**: FAQ and support documentation
- **Code Analysis**: Code documentation and analysis

## Performance Tips

1. **Batch Processing**: Process documents in batches
2. **Persistent Storage**: Use persistent vector stores
3. **Incremental Updates**: Update indexes incrementally
4. **Query Caching**: Cache frequent queries
5. **Embedding Caching**: Cache document embeddings

## Documentation

- [LlamaIndex Documentation](https://docs.llamaindex.ai/)
- [Getting Started Guide](https://docs.llamaindex.ai/en/stable/getting_started/starter_example.html)
- [API Reference](https://docs.llamaindex.ai/en/stable/api_reference/)
- [Examples Repository](https://github.com/run-llama/llama_index/tree/main/examples)