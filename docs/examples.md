# Spinbox Examples Documentation

This document provides a comprehensive guide to all available examples in Spinbox, their contents, setup instructions, and the rationale behind each example.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Core Component Examples](#core-component-examples)
3. [Component Combination Examples](#component-combination-examples)
4. [AI/LLM Integration Examples](#aillm-integration-examples)
5. [Data Science Examples](#data-science-examples)
6. [Setup and Usage Instructions](#setup-and-usage-instructions)
7. [Troubleshooting Guide](#troubleshooting-guide)

## Overview

Spinbox includes working code examples for all components and their combinations. These examples demonstrate best practices, security patterns, and real-world usage scenarios. All examples are production-ready and follow industry standards.

### Using Examples

Add examples to any project with the `--with-examples` flag:

```bash
# Add examples during project creation
spinbox create myproject --profile web-app --with-examples

# Add examples to existing project
spinbox add --fastapi --with-examples
```

## Core Component Examples

### FastAPI Examples
**Location**: `templates/examples/core-components/fastapi/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-basic-crud.py** - Complete CRUD operations with proper error handling
- **example-auth-simple.py** - JWT authentication with user management
- **example-websocket.py** - Real-time WebSocket communication

#### Rationale:
FastAPI is the most complex component requiring comprehensive examples covering:
- Database operations (CRUD)
- Authentication and security
- Real-time communication
- Error handling patterns

### Next.js Examples
**Location**: `templates/examples/core-components/nextjs/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-basic-app.tsx** - Basic Next.js app structure with routing
- **example-api-routes.ts** - API route examples with validation
- **example-components.tsx** - Reusable component library

#### Rationale:
Next.js examples focus on:
- Modern React patterns
- TypeScript integration
- API route best practices
- Component composition

### PostgreSQL Examples
**Location**: `templates/examples/core-components/postgresql/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-schema.sql** - Proper database schema design
- **example-queries.sql** - Common SQL query patterns
- **example-migrations.sql** - Database migration examples

#### Rationale:
PostgreSQL examples demonstrate:
- Schema design best practices
- Query optimization
- Migration strategies
- Security considerations

### Redis Examples
**Location**: `templates/examples/core-components/redis/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-caching.py** - Caching patterns and strategies
- **example-queues.py** - Queue/task management
- **example-pub-sub.py** - Publish/subscribe messaging

#### Rationale:
Redis examples cover:
- Caching strategies
- Task queues
- Real-time messaging
- Performance optimization

### MongoDB Examples
**Location**: `templates/examples/core-components/mongodb/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-models.py** - Beanie/Motor model definitions
- **example-operations.py** - Document CRUD operations
- **example-aggregations.py** - Aggregation pipeline examples

#### Rationale:
MongoDB examples demonstrate:
- Document modeling
- Aggregation pipelines
- Index optimization
- NoSQL best practices

### Chroma Examples
**Location**: `templates/examples/core-components/chroma/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-vector-store.py** - Vector storage and retrieval
- **example-embeddings.py** - Embedding generation and management
- **example-similarity-search.py** - Similarity search implementations

#### Rationale:
Chroma examples focus on:
- Vector database operations
- Embedding management
- Similarity search
- AI/ML integration

## Component Combination Examples

### FastAPI + PostgreSQL
**Location**: `templates/examples/combinations/two-component/fastapi-postgresql/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-basic-crud.py** - Complete CRUD API with PostgreSQL backend

#### Rationale:
This is the most common backend combination, demonstrating:
- Database connectivity
- ORM integration (SQLAlchemy)
- API endpoint design
- Transaction management

### FastAPI + Redis
**Location**: `templates/examples/combinations/two-component/fastapi-redis/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-caching-api.py** - API with Redis caching implementation

#### Rationale:
Shows how to integrate caching for:
- Performance optimization
- Session management
- API response caching
- Rate limiting

### FastAPI + OpenAI
**Location**: `templates/examples/combinations/two-component/fastapi-openai/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-chat-api.py** - Chat API with OpenAI integration
- **example-embeddings-api.py** - Embeddings generation API
- **example-function-calling-api.py** - Function calling with OpenAI

#### Rationale:
Demonstrates AI integration patterns:
- API key management
- Cost optimization
- Error handling for external APIs
- Streaming responses

### FastAPI + LangChain
**Location**: `templates/examples/combinations/two-component/fastapi-langchain/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-rag-system.py** - Complete RAG (Retrieval-Augmented Generation) system

#### Rationale:
Shows complex AI workflows:
- Document processing
- Vector store integration
- Query processing
- Response generation

### Next.js + FastAPI
**Location**: `templates/examples/combinations/two-component/nextjs-fastapi/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-todo-app-backend.py** - Backend for todo application

#### Rationale:
Full-stack development patterns:
- API client integration
- State management
- Error handling
- TypeScript integration

### FastAPI + Data Science
**Location**: `templates/examples/combinations/two-component/fastapi-data-science/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-data-analysis-api.py** - Data analysis API with pandas/numpy

#### Rationale:
Data science workflow integration:
- Data processing APIs
- Statistical analysis
- Visualization endpoints
- File upload handling

## AI/LLM Integration Examples

### OpenAI Examples
**Location**: `templates/examples/ai-llm/openai/`
**Status**: ✅ **Complete**

#### Available Examples:
- **example-chat.py** - Direct OpenAI chat integration
- **example-embeddings.py** - Text embedding generation

#### Rationale:
Foundation for AI applications:
- API key management
- Cost optimization
- Error handling
- Response processing

### Anthropic Examples
**Location**: `templates/examples/ai-llm/anthropic/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-chat.py** - Claude chat integration
- **example-function-calling.py** - Function calling with Claude

#### Rationale:
Alternative AI provider integration:
- Multi-provider support
- Different model capabilities
- Cost comparison
- Fallback strategies

### LangChain Examples
**Location**: `templates/examples/ai-llm/langchain/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-rag-basic.py** - Basic RAG implementation
- **example-chains.py** - LangChain chains
- **example-agents.py** - AI agent examples

#### Rationale:
Complex AI workflows:
- Multi-step processing
- Agent frameworks
- Tool integration
- Workflow orchestration

### LlamaIndex Examples
**Location**: `templates/examples/ai-llm/llamaindex/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-indexing.py** - Document indexing
- **example-querying.py** - Query engine examples
- **example-multi-modal.py** - Multi-modal processing

#### Rationale:
Document processing focus:
- Index management
- Query optimization
- Multi-modal support
- Performance tuning

## Data Science Examples

### Data Science Examples
**Location**: `templates/examples/data-science/`
**Status**: ❌ **Incomplete - Needs Implementation**

#### Planned Examples:
- **example-pandas-analysis.py** - Data analysis with pandas
- **example-visualization.py** - Data visualization
- **example-ml-pipeline.py** - Machine learning pipeline
- **example-jupyter-setup.py** - Jupyter notebook integration

#### Rationale:
Data science workflow support:
- Data processing
- Statistical analysis
- Visualization
- Model training

## Setup and Usage Instructions

### General Setup

1. **Create project with examples:**
   ```bash
   spinbox create myproject --profile web-app --with-examples
   ```

2. **Navigate to project:**
   ```bash
   cd myproject
   ```

3. **Open in DevContainer:**
   ```bash
   code .
   # Click "Reopen in Container" when prompted
   ```

### Component-Specific Setup

#### FastAPI Examples
```bash
# Navigate to backend directory
cd backend

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run example
python example-basic-crud.py
```

#### Next.js Examples
```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Set up environment
cp .env.local.example .env.local
# Edit .env.local with your configuration

# Run development server
npm run dev
```

#### Database Examples
```bash
# For PostgreSQL examples
psql -U postgres -d myproject < example-schema.sql

# For MongoDB examples
mongosh myproject < example-operations.js
```

### AI/LLM Examples Setup

#### OpenAI Examples
```bash
# Set up API key
export OPENAI_API_KEY="your-api-key-here"

# Or add to .env file
echo "OPENAI_API_KEY=your-api-key-here" >> .env

# Run example
python example-chat.py
```

#### Cost Management for AI Examples
- **Set usage limits** in your AI provider dashboard
- **Monitor costs** with the provided usage tracking examples
- **Use cheaper models** for development (e.g., gpt-3.5-turbo instead of gpt-4)
- **Implement caching** to reduce API calls

## Troubleshooting Guide

### Common Issues

#### Examples Not Found
**Problem**: Examples not copied to project
**Solution**: Ensure you used the `--with-examples` flag

#### Import Errors
**Problem**: Missing dependencies
**Solution**: Check requirements.txt and install all dependencies

#### API Key Issues
**Problem**: AI examples fail with authentication errors
**Solution**: Verify API key is correctly set in environment variables

#### Database Connection Issues
**Problem**: Database examples fail to connect
**Solution**: Ensure database service is running and credentials are correct

### Performance Issues

#### AI Examples Running Slowly
- Use appropriate model sizes for your use case
- Implement caching for repeated queries
- Consider using async operations

#### Database Examples Slow
- Check database indexes
- Optimize queries
- Use connection pooling

### Security Considerations

#### Environment Variables
- Never commit `.env` files to version control
- Use different API keys for development and production
- Regularly rotate API keys

#### Database Security
- Use strong passwords
- Enable SSL/TLS connections
- Implement proper access controls

### Getting Help

1. **Check example documentation** in each example directory
2. **Review error logs** in the DevContainer
3. **Consult component-specific documentation**
4. **Use debugging tools** provided in examples

## Contributing Examples

### Guidelines for New Examples

1. **Follow naming convention**: `example-[functionality].py`
2. **Include comprehensive README**: Setup, usage, and troubleshooting
3. **Add error handling**: Proper exception handling and user feedback
4. **Include security best practices**: Environment variables, input validation
5. **Add comments**: Explain complex logic and best practices
6. **Test thoroughly**: Ensure examples work in DevContainer environment

### Example Template

```python
#!/usr/bin/env python3
"""
Example: [Brief description]

This example demonstrates [detailed description].

Prerequisites:
- [List prerequisites]

Setup:
1. [Setup step 1]
2. [Setup step 2]

Usage:
python example-[name].py

Author: Spinbox Team
License: MIT
"""

import os
from typing import Optional

def main():
    """Main example function."""
    # Implementation here
    pass

if __name__ == "__main__":
    main()
```

---

*This documentation is maintained alongside the Spinbox codebase. For the latest updates, check the [GitHub repository](https://github.com/Gonzillaaa/spinbox).*