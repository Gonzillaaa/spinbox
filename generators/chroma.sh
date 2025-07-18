#!/bin/bash
# Chroma vector database component generator for Spinbox
# Creates Chroma vector database for AI/ML embeddings and vector search

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/dependency-manager.sh"

# Generate Chroma vector database component
function generate_chroma_component() {
    local project_dir="$1"
    local chroma_dir="$project_dir/chroma_data"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate Chroma vector database component"
        return 0
    fi
    
    print_status "Creating Chroma vector database component..."
    
    # Ensure chroma directories exist
    safe_create_dir "$chroma_dir"
    safe_create_dir "$project_dir/vector_db"
    safe_create_dir "$project_dir/vector_db/scripts"
    safe_create_dir "$project_dir/vector_db/examples"
    
    # Generate chroma files
    generate_chroma_config "$project_dir"
    generate_chroma_scripts "$project_dir"
    generate_chroma_examples "$project_dir"
    generate_chroma_env_files "$project_dir"
    
    # Manage dependencies if --with-deps flag is enabled
    manage_component_dependencies "$project_dir" "chroma"
    
    print_status "Chroma vector database component created successfully"
}

# Generate Chroma configuration
function generate_chroma_config() {
    local project_dir="$1"
    
    # Chroma configuration file
    cat > "$project_dir/vector_db/chroma_config.py" << EOF
# Chroma vector database configuration for ${PROJECT_NAME:-app}
# Generated by Spinbox on $(date)

import chromadb
from chromadb.config import Settings
import os

# Configuration
CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", "./chroma_data")
CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = int(os.getenv("CHROMA_PORT", "8000"))

# Chroma client configuration
def get_chroma_client():
    """Get Chroma client instance"""
    return chromadb.PersistentClient(
        path=CHROMA_DB_PATH,
        settings=Settings(
            anonymized_telemetry=False,
            allow_reset=True
        )
    )

# HTTP client for remote Chroma server (optional)
def get_chroma_http_client():
    """Get Chroma HTTP client for remote server"""
    return chromadb.HttpClient(
        host=CHROMA_HOST,
        port=CHROMA_PORT,
        settings=Settings(
            anonymized_telemetry=False
        )
    )

# Collection settings
DEFAULT_COLLECTION_NAME = "${PROJECT_NAME:-app}_documents"
DEFAULT_EMBEDDING_FUNCTION = "default"  # Uses sentence-transformers

# Metadata configuration
METADATA_SCHEMA = {
    "source": str,
    "type": str,
    "created_at": str,
    "updated_at": str,
    "author": str,
    "category": str
}
EOF

    # Docker Compose service (optional Chroma server)
    cat > "$project_dir/vector_db/docker-compose.yml" << EOF
# Chroma vector database service for ${PROJECT_NAME:-app}
# Generated by Spinbox on $(date)
# NOTE: This is optional - Chroma can run embedded in your Python app

version: '3.8'

services:
  chroma:
    image: chromadb/chroma:latest
    container_name: ${PROJECT_NAME:-app}_chroma
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - chroma_data:/chroma/chroma
    environment:
      - CHROMA_SERVER_HTTP_PORT=8000
      - CHROMA_SERVER_GRPC_PORT=50051
      - CHROMA_DB_PATH=/chroma/chroma
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/v1/heartbeat"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

volumes:
  chroma_data:
    driver: local

networks:
  app_network:
    driver: bridge
EOF

    # .gitignore for chroma data
    cat > "$project_dir/chroma_data/.gitignore" << EOF
# Ignore all files in chroma_data directory
*

# But track this .gitignore file
!.gitignore

# Optional: allow specific files to be tracked
# !important_collection.json
EOF
}

# Generate utility scripts
function generate_chroma_scripts() {
    local project_dir="$1"
    local scripts_dir="$project_dir/vector_db/scripts"
    
    # Database reset script
    cat > "$scripts_dir/reset_db.py" << 'EOF'
#!/usr/bin/env python3
"""Reset Chroma database"""

import sys
import os
sys.path.append('..')

from chroma_config import get_chroma_client

def reset_database():
    """Reset the Chroma database"""
    try:
        client = get_chroma_client()
        client.reset()
        print("✅ Chroma database reset successfully")
    except Exception as e:
        print(f"❌ Error resetting database: {e}")
        return 1
    return 0

if __name__ == "__main__":
    exit(reset_database())
EOF

    # Collection management script
    cat > "$scripts_dir/manage_collections.py" << 'EOF'
#!/usr/bin/env python3
"""Manage Chroma collections"""

import sys
import os
import argparse
sys.path.append('..')

from chroma_config import get_chroma_client, DEFAULT_COLLECTION_NAME

def list_collections():
    """List all collections"""
    client = get_chroma_client()
    collections = client.list_collections()
    
    if not collections:
        print("No collections found")
        return
    
    print("Collections:")
    for collection in collections:
        count = collection.count()
        print(f"  - {collection.name} ({count} documents)")

def create_collection(name: str):
    """Create a new collection"""
    client = get_chroma_client()
    try:
        collection = client.create_collection(name=name)
        print(f"✅ Created collection: {name}")
    except Exception as e:
        print(f"❌ Error creating collection: {e}")

def delete_collection(name: str):
    """Delete a collection"""
    client = get_chroma_client()
    try:
        client.delete_collection(name=name)
        print(f"✅ Deleted collection: {name}")
    except Exception as e:
        print(f"❌ Error deleting collection: {e}")

def collection_info(name: str):
    """Show collection information"""
    client = get_chroma_client()
    try:
        collection = client.get_collection(name=name)
        count = collection.count()
        
        print(f"Collection: {name}")
        print(f"Document count: {count}")
        
        if count > 0:
            # Show a sample document
            results = collection.peek(limit=1)
            if results['documents']:
                print(f"Sample document: {results['documents'][0][:100]}...")
                if results['metadatas'] and results['metadatas'][0]:
                    print(f"Sample metadata: {results['metadatas'][0]}")
    except Exception as e:
        print(f"❌ Error getting collection info: {e}")

def main():
    parser = argparse.ArgumentParser(description="Manage Chroma collections")
    parser.add_argument("action", choices=["list", "create", "delete", "info"])
    parser.add_argument("--name", help="Collection name")
    
    args = parser.parse_args()
    
    if args.action == "list":
        list_collections()
    elif args.action == "create":
        if not args.name:
            print("❌ Collection name required for create action")
            return 1
        create_collection(args.name)
    elif args.action == "delete":
        if not args.name:
            print("❌ Collection name required for delete action")
            return 1
        delete_collection(args.name)
    elif args.action == "info":
        if not args.name:
            print("❌ Collection name required for info action")
            return 1
        collection_info(args.name)

if __name__ == "__main__":
    main()
EOF

    # Backup script
    cat > "$scripts_dir/backup.py" << 'EOF'
#!/usr/bin/env python3
"""Backup Chroma collections"""

import sys
import os
import json
import zipfile
from datetime import datetime
sys.path.append('..')

from chroma_config import get_chroma_client

def backup_collections(backup_path: str = None):
    """Backup all collections to JSON files"""
    if not backup_path:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = f"backup_{timestamp}.zip"
    
    client = get_chroma_client()
    collections = client.list_collections()
    
    if not collections:
        print("No collections to backup")
        return
    
    with zipfile.ZipFile(backup_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for collection in collections:
            print(f"Backing up collection: {collection.name}")
            
            # Get all documents
            results = collection.get(include=['documents', 'metadatas', 'embeddings'])
            
            backup_data = {
                "name": collection.name,
                "count": len(results.get('documents', [])),
                "documents": results.get('documents', []),
                "metadatas": results.get('metadatas', []),
                "ids": results.get('ids', []),
                "embeddings": results.get('embeddings', [])
            }
            
            # Write to JSON file in zip
            json_data = json.dumps(backup_data, indent=2)
            zipf.writestr(f"{collection.name}.json", json_data)
    
    print(f"✅ Backup completed: {backup_path}")

if __name__ == "__main__":
    backup_path = sys.argv[1] if len(sys.argv) > 1 else None
    backup_collections(backup_path)
EOF

    # Make scripts executable
    chmod +x "$scripts_dir"/*.py
}

# Generate example code
function generate_chroma_examples() {
    local project_dir="$1"
    local examples_dir="$project_dir/vector_db/examples"
    
    # Basic usage example
    cat > "$examples_dir/basic_usage.py" << 'EOF'
#!/usr/bin/env python3
"""Basic Chroma usage example"""

import sys
sys.path.append('..')

from chroma_config import get_chroma_client, DEFAULT_COLLECTION_NAME

def main():
    """Demonstrate basic Chroma operations"""
    # Get client
    client = get_chroma_client()
    
    # Create or get collection
    collection = client.get_or_create_collection(
        name=DEFAULT_COLLECTION_NAME,
        metadata={"description": "Sample document collection"}
    )
    
    # Add some sample documents
    documents = [
        "This is a document about artificial intelligence and machine learning.",
        "Python is a great programming language for data science.",
        "Vector databases are useful for similarity search and retrieval.",
        "Chroma is an open-source vector database for AI applications."
    ]
    
    metadatas = [
        {"topic": "AI", "type": "article"},
        {"topic": "Programming", "type": "tutorial"},
        {"topic": "Database", "type": "article"},
        {"topic": "Database", "type": "documentation"}
    ]
    
    ids = [f"doc_{i}" for i in range(len(documents))]
    
    # Add documents to collection
    collection.add(
        documents=documents,
        metadatas=metadatas,
        ids=ids
    )
    
    print(f"Added {len(documents)} documents to collection")
    print(f"Collection now has {collection.count()} documents")
    
    # Query the collection
    query_text = "What is machine learning?"
    results = collection.query(
        query_texts=[query_text],
        n_results=2,
        include=['documents', 'metadatas', 'distances']
    )
    
    print(f"\nQuery: {query_text}")
    print("Results:")
    for i, (doc, metadata, distance) in enumerate(zip(
        results['documents'][0],
        results['metadatas'][0],
        results['distances'][0]
    )):
        print(f"  {i+1}. (distance: {distance:.3f}) {doc[:100]}...")
        print(f"     Metadata: {metadata}")

if __name__ == "__main__":
    main()
EOF

    # FastAPI integration example
    cat > "$examples_dir/fastapi_integration.py" << 'EOF'
"""FastAPI integration with Chroma vector database"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import sys
sys.path.append('..')

from chroma_config import get_chroma_client, DEFAULT_COLLECTION_NAME

app = FastAPI(title="Vector Search API")

# Pydantic models
class DocumentAdd(BaseModel):
    id: str
    content: str
    metadata: Optional[Dict[str, Any]] = None

class DocumentQuery(BaseModel):
    query: str
    n_results: int = 10
    filter_metadata: Optional[Dict[str, Any]] = None

class SearchResult(BaseModel):
    id: str
    content: str
    metadata: Dict[str, Any]
    distance: float

# Global collection
collection = None

@app.on_event("startup")
async def startup_event():
    """Initialize Chroma collection"""
    global collection
    client = get_chroma_client()
    collection = client.get_or_create_collection(
        name=DEFAULT_COLLECTION_NAME,
        metadata={"description": "API document collection"}
    )

@app.post("/documents/add")
async def add_document(doc: DocumentAdd):
    """Add a document to the vector database"""
    try:
        collection.add(
            documents=[doc.content],
            metadatas=[doc.metadata or {}],
            ids=[doc.id]
        )
        return {"status": "success", "id": doc.id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/documents/search", response_model=List[SearchResult])
async def search_documents(query: DocumentQuery):
    """Search for similar documents"""
    try:
        results = collection.query(
            query_texts=[query.query],
            n_results=query.n_results,
            where=query.filter_metadata,
            include=['documents', 'metadatas', 'distances']
        )
        
        search_results = []
        for i, (doc, metadata, distance) in enumerate(zip(
            results['documents'][0],
            results['metadatas'][0],
            results['distances'][0]
        )):
            search_results.append(SearchResult(
                id=results['ids'][0][i],
                content=doc,
                metadata=metadata,
                distance=distance
            ))
        
        return search_results
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/collections/info")
async def collection_info():
    """Get collection information"""
    return {
        "name": collection.name,
        "count": collection.count(),
        "metadata": collection.metadata
    }

@app.delete("/documents/{doc_id}")
async def delete_document(doc_id: str):
    """Delete a document by ID"""
    try:
        collection.delete(ids=[doc_id])
        return {"status": "success", "deleted_id": doc_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

    # Document processing example
    cat > "$examples_dir/document_processor.py" << 'EOF'
"""Document processing and embedding example"""

import sys
import os
from typing import List, Dict, Any
from pathlib import Path
sys.path.append('..')

from chroma_config import get_chroma_client

class DocumentProcessor:
    """Process and store documents in Chroma"""
    
    def __init__(self, collection_name: str = "processed_documents"):
        self.client = get_chroma_client()
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"description": "Processed document collection"}
        )
    
    def add_text_file(self, file_path: str, chunk_size: int = 1000) -> List[str]:
        """Add a text file to the collection, splitting into chunks"""
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        # Read file content
        content = path.read_text(encoding='utf-8')
        
        # Split into chunks
        chunks = self._split_text(content, chunk_size)
        
        # Generate IDs and metadata
        ids = [f"{path.stem}_chunk_{i}" for i in range(len(chunks))]
        metadatas = [
            {
                "source": str(path),
                "chunk_index": i,
                "total_chunks": len(chunks),
                "file_size": len(content)
            }
            for i in range(len(chunks))
        ]
        
        # Add to collection
        self.collection.add(
            documents=chunks,
            metadatas=metadatas,
            ids=ids
        )
        
        return ids
    
    def _split_text(self, text: str, chunk_size: int) -> List[str]:
        """Split text into chunks"""
        chunks = []
        words = text.split()
        
        current_chunk = []
        current_size = 0
        
        for word in words:
            if current_size + len(word) + 1 > chunk_size and current_chunk:
                chunks.append(' '.join(current_chunk))
                current_chunk = [word]
                current_size = len(word)
            else:
                current_chunk.append(word)
                current_size += len(word) + 1
        
        if current_chunk:
            chunks.append(' '.join(current_chunk))
        
        return chunks
    
    def search_documents(self, query: str, n_results: int = 5) -> List[Dict[str, Any]]:
        """Search for relevant document chunks"""
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results,
            include=['documents', 'metadatas', 'distances']
        )
        
        search_results = []
        for i in range(len(results['documents'][0])):
            search_results.append({
                'content': results['documents'][0][i],
                'metadata': results['metadatas'][0][i],
                'distance': results['distances'][0][i],
                'id': results['ids'][0][i]
            })
        
        return search_results

def main():
    """Example usage"""
    processor = DocumentProcessor()
    
    # Example: process a README file
    readme_path = "../../README.md"
    if os.path.exists(readme_path):
        print(f"Processing {readme_path}...")
        ids = processor.add_text_file(readme_path, chunk_size=500)
        print(f"Added {len(ids)} chunks to collection")
        
        # Search example
        query = "How to install and use this tool?"
        results = processor.search_documents(query, n_results=3)
        
        print(f"\nSearch results for: {query}")
        for i, result in enumerate(results, 1):
            print(f"{i}. (distance: {result['distance']:.3f})")
            print(f"   {result['content'][:200]}...")
            print(f"   Source: {result['metadata']['source']}")
            print()

if __name__ == "__main__":
    main()
EOF
}

# Generate environment files
function generate_chroma_env_files() {
    local project_dir="$1"
    
    # Environment variables for Chroma
    cat > "$project_dir/vector_db/.env.chroma" << EOF
# Chroma vector database environment variables
# Generated by Spinbox on $(date)

# Local/Embedded configuration
CHROMA_DB_PATH=./chroma_data
CHROMA_ANONYMIZED_TELEMETRY=false

# Remote server configuration (if using HTTP client)
CHROMA_HOST=localhost
CHROMA_PORT=8000
CHROMA_SERVER_HTTP_PORT=8000
CHROMA_SERVER_GRPC_PORT=50051

# Collection settings
DEFAULT_COLLECTION_NAME=${PROJECT_NAME:-app}_documents
CHROMA_MAX_BATCH_SIZE=1000

# Embedding settings
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
EMBEDDING_DEVICE=cpu
EOF

    # Requirements for Chroma integration
    cat > "$project_dir/vector_db/requirements.txt" << EOF
# Chroma vector database dependencies
# Generated by Spinbox on $(date)

chromadb>=0.4.15          # Vector database
sentence-transformers>=2.2.2  # Default embedding model
transformers>=4.21.0      # Transformer models
torch>=2.0.0              # PyTorch for embeddings
numpy>=1.21.0             # Numerical computing
pydantic>=2.0.0           # Data validation
fastapi>=0.100.0          # Web API framework
uvicorn>=0.23.0           # ASGI server

# Optional dependencies for advanced features
# tiktoken>=0.5.0         # Token counting for OpenAI models
# openai>=1.0.0           # OpenAI embeddings
# cohere>=4.0.0           # Cohere embeddings
# huggingface-hub>=0.16.0 # HuggingFace model hub
EOF

    # FastAPI integration helper
    cat > "$project_dir/vector_db/vector_service.py" << EOF
# Vector database service for FastAPI integration
# Generated by Spinbox on $(date)

from typing import List, Dict, Any, Optional
import logging
from chroma_config import get_chroma_client, DEFAULT_COLLECTION_NAME

logger = logging.getLogger(__name__)

class VectorService:
    """Service class for vector database operations"""
    
    def __init__(self, collection_name: str = None):
        self.client = get_chroma_client()
        self.collection_name = collection_name or DEFAULT_COLLECTION_NAME
        self.collection = None
        self._initialize_collection()
    
    def _initialize_collection(self):
        """Initialize or get collection"""
        try:
            self.collection = self.client.get_or_create_collection(
                name=self.collection_name,
                metadata={"description": f"Collection for {self.collection_name}"}
            )
            logger.info(f"Initialized collection: {self.collection_name}")
        except Exception as e:
            logger.error(f"Failed to initialize collection: {e}")
            raise
    
    async def add_document(self, doc_id: str, content: str, metadata: Dict[str, Any] = None) -> bool:
        """Add a single document"""
        try:
            self.collection.add(
                documents=[content],
                metadatas=[metadata or {}],
                ids=[doc_id]
            )
            return True
        except Exception as e:
            logger.error(f"Failed to add document {doc_id}: {e}")
            return False
    
    async def add_documents(self, documents: List[Dict[str, Any]]) -> int:
        """Add multiple documents"""
        try:
            doc_contents = [doc['content'] for doc in documents]
            doc_ids = [doc['id'] for doc in documents]
            doc_metadatas = [doc.get('metadata', {}) for doc in documents]
            
            self.collection.add(
                documents=doc_contents,
                metadatas=doc_metadatas,
                ids=doc_ids
            )
            return len(documents)
        except Exception as e:
            logger.error(f"Failed to add documents: {e}")
            return 0
    
    async def search(self, query: str, n_results: int = 10, filter_metadata: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """Search for similar documents"""
        try:
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results,
                where=filter_metadata,
                include=['documents', 'metadatas', 'distances']
            )
            
            search_results = []
            for i in range(len(results['documents'][0])):
                search_results.append({
                    'id': results['ids'][0][i],
                    'content': results['documents'][0][i],
                    'metadata': results['metadatas'][0][i],
                    'distance': results['distances'][0][i]
                })
            
            return search_results
        except Exception as e:
            logger.error(f"Search failed: {e}")
            return []
    
    async def delete_document(self, doc_id: str) -> bool:
        """Delete a document by ID"""
        try:
            self.collection.delete(ids=[doc_id])
            return True
        except Exception as e:
            logger.error(f"Failed to delete document {doc_id}: {e}")
            return False
    
    async def get_collection_info(self) -> Dict[str, Any]:
        """Get collection information"""
        try:
            return {
                "name": self.collection.name,
                "count": self.collection.count(),
                "metadata": self.collection.metadata
            }
        except Exception as e:
            logger.error(f"Failed to get collection info: {e}")
            return {}

# Global service instance
vector_service = VectorService()

async def get_vector_service() -> VectorService:
    """Dependency for FastAPI"""
    return vector_service
EOF
}

# Main execution function
function main() {
    local project_dir="${1:-.}"
    
    # Validate project directory
    if [[ ! -d "$project_dir" ]]; then
        print_error "Project directory does not exist: $project_dir"
        return 1
    fi
    
    # Generate Chroma component
    generate_chroma_component "$project_dir"
    
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi