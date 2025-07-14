# Chroma Vector Database Usage

Chroma is a lightweight vector database that's perfect for storing and searching document embeddings. When you add Chroma to your project with `spinbox add --chroma`, it's automatically integrated with your FastAPI backend.

## Features

- **Persistent Storage**: Vector data is stored in the `chroma_data/` directory  
- **Python Integration**: Direct Python API for adding and searching documents
- **Similarity Search**: Find documents similar to a query text
- **Metadata Support**: Store additional information with each document

> **Note**: This documentation describes the available Chroma features. The specific API endpoints shown below represent example implementations that can be built with the Chroma dependency included in FastAPI projects.

## Example API Endpoints

### Add Document
```http
POST /api/vector/add
Content-Type: application/json

{
  "id": "doc_1",
  "content": "This is my document content",
  "metadata": {
    "title": "My Document",
    "category": "example"
  }
}
```

### Search Documents
```http
POST /api/vector/search
Content-Type: application/json

{
  "query": "find similar documents",
  "n_results": 10
}
```

### List Collections
```http
GET /api/vector/collections
```

### Delete Collection
```http
DELETE /api/vector/collection/{collection_name}
```

## Usage Examples

### Adding Documents with Python

```python
import requests

# Add a document
response = requests.post("http://localhost:8000/api/vector/add", json={
    "id": "doc_1",
    "content": "Machine learning is a subset of artificial intelligence",
    "metadata": {
        "topic": "AI",
        "date": "2024-01-01"
    }
})

print(response.json())
```

### Searching Documents

```python
import requests

# Search for similar documents
response = requests.post("http://localhost:8000/api/vector/search", json={
    "query": "What is AI?",
    "n_results": 5
})

results = response.json()
print(f"Found {len(results['results']['documents'][0])} similar documents")
```

### Using with JavaScript/TypeScript

```typescript
// Add a document
const addDocument = async (id: string, content: string, metadata: any = {}) => {
  const response = await fetch('/api/vector/add', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      id,
      content,
      metadata,
    }),
  });
  return response.json();
};

// Search documents
const searchDocuments = async (query: string, n_results: number = 10) => {
  const response = await fetch('/api/vector/search', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query,
      n_results,
    }),
  });
  return response.json();
};
```

## Configuration

The Chroma client is initialized in your FastAPI backend with the following settings:

```python
import chromadb
from chromadb.config import Settings

chroma_client = chromadb.Client(Settings(
    persist_directory="./chroma_data",
    anonymized_telemetry=False
))
```

## Data Storage

- **Location**: `chroma_data/` directory in your project root
- **Persistence**: Data is automatically saved to disk
- **Backup**: The directory is excluded from git (in `.gitignore`)

## Advanced Usage

### Creating Custom Collections

```python
# Create a new collection
collection = chroma_client.create_collection(
    name="my_collection",
    metadata={"description": "My custom collection"}
)

# Add documents to specific collection
collection.add(
    documents=["Document 1", "Document 2"],
    metadatas=[{"type": "A"}, {"type": "B"}],
    ids=["id1", "id2"]
)
```

### Using Custom Embedding Functions

```python
from chromadb.utils import embedding_functions

# Use OpenAI embeddings
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="your-api-key",
    model_name="text-embedding-ada-002"
)

collection = chroma_client.create_collection(
    name="openai_collection",
    embedding_function=openai_ef
)
```

### Filtering Results

```python
# Search with metadata filtering
results = collection.query(
    query_texts=["AI and machine learning"],
    n_results=5,
    where={"topic": "AI"}
)
```

## Best Practices

1. **Unique IDs**: Always use unique document IDs
2. **Chunking**: Break large documents into smaller chunks
3. **Metadata**: Use metadata for filtering and organization
4. **Batch Operations**: Add multiple documents in batches for better performance
5. **Error Handling**: Always handle API errors gracefully

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Ensure port 8000 is available
2. **Permissions**: Check write permissions for `chroma_data/` directory
3. **Memory**: Large collections may require more RAM

### Debugging

```python
# Check collection info
print(collection.count())
print(collection.peek())

# List all collections
collections = chroma_client.list_collections()
for col in collections:
    print(f"Collection: {col.name}")
```

## Implementation Status

When you add Chroma to a Spinbox project with `spinbox add --chroma`, the following is automatically configured:
- Chroma Python dependency in requirements.txt
- Basic project structure with `chroma_data/` directory
- `.gitignore` entries for the vector database files

The API endpoints shown above are examples of what you can build with the included Chroma dependency. They represent common patterns for vector database integration with FastAPI.

## References

- [Chroma Documentation](https://docs.trychroma.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Vector Database Concepts](https://www.pinecone.io/learn/vector-database/)