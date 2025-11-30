# Chroma Vector Database

Chroma is a lightweight vector database for storing and searching document embeddings.

## What You Get

When you add Chroma with `spinbox add --chroma`:
- Chroma dependency in `requirements.txt`
- `chroma/` directory for persistent storage
- `.gitignore` entries for vector database files

**Note**: The API endpoints below are examples you implement yourself. Spinbox provides the foundation; you build the functionality.

## Basic Setup

```python
import chromadb
from chromadb.config import Settings

client = chromadb.Client(Settings(
    persist_directory="./chroma",
    anonymized_telemetry=False
))

# Create collection
collection = client.create_collection("documents")

# Add documents
collection.add(
    documents=["Machine learning is a subset of AI"],
    metadatas=[{"topic": "AI"}],
    ids=["doc1"]
)

# Search
results = collection.query(
    query_texts=["What is AI?"],
    n_results=5
)
```

## Custom Embeddings

```python
from chromadb.utils import embedding_functions

# Use OpenAI embeddings
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="your-api-key",
    model_name="text-embedding-ada-002"
)

collection = client.create_collection(
    name="openai_collection",
    embedding_function=openai_ef
)
```

## Filtering Results

```python
results = collection.query(
    query_texts=["AI and machine learning"],
    n_results=5,
    where={"topic": "AI"}
)
```

## Best Practices

1. Use unique document IDs
2. Break large documents into chunks
3. Use metadata for filtering
4. Batch operations for better performance

## Data Storage

- Location: `chroma/` directory
- Persistence: Automatic
- Excluded from git by default

## References

- [Chroma Documentation](https://docs.trychroma.com/)
