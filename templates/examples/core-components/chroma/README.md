# Chroma Vector Database Examples

This directory contains working examples for Chroma vector database operations that demonstrate AI/ML applications and vector similarity search.

## 📋 Available Examples

### Core Examples
- **example-basic-operations.js** - Basic vector operations and collections
- **example-similarity-search.js** - Vector similarity search and retrieval
- **example-embeddings.js** - Text embeddings and semantic search
- **example-rag-system.js** - Retrieval-Augmented Generation (RAG) implementation
- **example-metadata-filtering.js** - Advanced filtering and querying

## 🚀 Setup Instructions

1. **Ensure Chroma is running:**
   ```bash
   docker-compose up -d chroma
   ```

2. **Install Chroma client:**
   ```bash
   npm install chromadb
   ```

3. **Test connection:**
   ```bash
   curl http://localhost:8000/api/v1/heartbeat
   ```

4. **Run examples:**
   ```bash
   node example-basic-operations.js
   node example-similarity-search.js
   node example-embeddings.js
   ```

## 📖 Example Details

### example-basic-operations.js
Demonstrates:
- Collection creation and management
- Document insertion and retrieval
- Basic vector operations
- Error handling
- Connection management

### example-similarity-search.js
Demonstrates:
- Vector similarity search
- Cosine similarity calculations
- Distance metrics
- Result ranking
- Query optimization

### example-embeddings.js
Demonstrates:
- Text-to-vector embeddings
- Semantic search capabilities
- Document chunking
- Embedding models integration
- Batch processing

### example-rag-system.js
Demonstrates:
- RAG (Retrieval-Augmented Generation)
- Context retrieval
- LLM integration patterns
- Response generation
- Knowledge base management

### example-metadata-filtering.js
Demonstrates:
- Advanced metadata filtering
- Complex query operations
- Hybrid search (vector + metadata)
- Performance optimization
- Index management

## 🔧 Integration Patterns

### With FastAPI
```python
from chromadb import Client
from sentence_transformers import SentenceTransformer

client = Client()
model = SentenceTransformer('all-MiniLM-L6-v2')

# Vector search endpoint
@app.post("/search")
async def search_documents(query: str):
    embeddings = model.encode([query])
    results = collection.query(
        query_embeddings=embeddings,
        n_results=10
    )
    return results
```

### With OpenAI Embeddings
```javascript
const { OpenAI } = require('openai');
const { ChromaClient } = require('chromadb');

const openai = new OpenAI();
const chroma = new ChromaClient();

async function embedText(text) {
    const response = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: text
    });
    return response.data[0].embedding;
}
```

## 📝 Notes

- Examples use Chroma 0.4+ features
- Includes OpenAI embeddings integration
- Demonstrates RAG patterns
- Shows performance optimization
- Includes error handling and retry logic
- Supports both local and cloud deployments