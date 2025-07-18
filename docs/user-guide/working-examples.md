# Working Examples Guide

The `--with-examples` flag includes working code examples with your Spinbox projects, providing immediate value and learning resources for each component.

## Quick Start

```bash
# Create a project with working examples
spinbox create myproject --fastapi --postgresql --with-examples

# Add a component with examples to existing project
spinbox add --chroma --with-examples
```

## What You Get

When you use `--with-examples`, Spinbox adds:

1. **Working code examples** for each component
2. **Documentation** explaining how to use each example
3. **Setup instructions** for running the examples
4. **Usage patterns** demonstrating best practices
5. **Integration examples** showing how components work together

## Example Types

### Core Component Examples

Each component includes focused examples demonstrating key functionality:

#### FastAPI Examples

- **`example-basic-crud.py`** - Complete CRUD operations with SQLAlchemy
- **`example-auth-simple.py`** - JWT authentication implementation
- **`example-websocket.py`** - Real-time WebSocket communication
- **`EXAMPLES.md`** - Setup and usage instructions

#### Next.js Examples

- **`example-basic-app.tsx`** - Basic Next.js app structure
- **`example-api-routes.ts`** - API route examples
- **`example-components.tsx`** - Reusable component examples
- **`EXAMPLES.md`** - Setup and usage instructions

#### PostgreSQL Examples

- **`example-schema.sql`** - Database schema examples
- **`example-queries.sql`** - Common SQL queries
- **`example-migrations.sql`** - Migration examples
- **`EXAMPLES.md`** - Setup and usage instructions

#### Redis Examples

- **`example-caching.js`** - Caching patterns and strategies
- **`example-pub-sub.js`** - Pub/Sub messaging examples
- **`example-sessions.js`** - Session management examples
- **`EXAMPLES.md`** - Setup and usage instructions

#### MongoDB Examples

- **`example-crud.js`** - CRUD operations with Mongoose
- **`example-aggregation.js`** - Aggregation pipeline examples
- **`EXAMPLES.md`** - Setup and usage instructions

#### Chroma Examples

- **`example-basic-operations.js`** - Basic vector operations
- **`example-rag-system.js`** - RAG (Retrieval-Augmented Generation) system
- **`EXAMPLES.md`** - Setup and usage instructions

### Combination Examples

When you use multiple components together, Spinbox provides integration examples:

#### FastAPI + PostgreSQL

```python
# example-basic-crud.py
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from .database import get_db
from .models import User
from .schemas import UserCreate, UserResponse

app = FastAPI()

@app.post("/users/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(name=user.name, email=user.email)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users/", response_model=List[UserResponse])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return users
```

#### Next.js + FastAPI

```typescript
// example-todo-app-backend.py (Next.js API client)
import { useState, useEffect } from 'react';

interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

export function useTodos() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/todos')
      .then(res => res.json())
      .then(data => {
        setTodos(data);
        setLoading(false);
      });
  }, []);

  const addTodo = async (title: string) => {
    const response = await fetch('/api/todos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, completed: false }),
    });
    const newTodo = await response.json();
    setTodos([...todos, newTodo]);
  };

  return { todos, loading, addTodo };
}
```

### Profile-Based Examples

Special examples for profile-based projects:

#### AI/LLM Examples

- **OpenAI Integration** - Chat completions, embeddings, function calling
- **Anthropic Integration** - Claude API integration
- **LangChain Examples** - RAG systems, conversation chains
- **Vector Database Integration** - Chroma + OpenAI embeddings

#### Data Science Examples

- **Data Analysis APIs** - FastAPI endpoints for ML models
- **Visualization Examples** - Matplotlib, Plotly integration
- **Data Processing** - Pandas workflows

## Usage Examples

### Basic Component Examples

```bash
# Create FastAPI project with examples
spinbox create api-project --fastapi --with-examples

# Result:
# fastapi/
# ├── EXAMPLES.md
# ├── example-basic-crud.py
# ├── example-auth-simple.py
# └── example-websocket.py
```

### Full-Stack Examples

```bash
# Create full-stack project with examples
spinbox create webapp --fastapi --nextjs --postgresql --with-examples

# Result:
# fastapi/
# ├── EXAMPLES.md
# ├── example-basic-crud.py (with PostgreSQL integration)
# ├── example-auth-simple.py
# └── example-websocket.py
# nextjs/
# ├── EXAMPLES.md
# ├── example-basic-app.tsx
# ├── example-api-routes.ts (with FastAPI integration)
# └── example-components.tsx
# postgresql/
# ├── EXAMPLES.md
# ├── example-schema.sql
# ├── example-queries.sql
# └── example-migrations.sql
```

### AI/ML Examples

```bash
# Create AI project with LLM examples
spinbox create ai-project --profile ai-llm --with-examples

# Result:
# examples/
# ├── ai-llm/
# │   ├── openai/
# │   │   ├── example-chat.py
# │   │   └── example-embeddings.py
# │   ├── anthropic/
# │   │   └── example-claude-chat.py
# │   └── langchain/
# │       └── example-rag-system.py
```

### Adding Examples to Existing Projects

```bash
# Add Redis with examples to existing project
cd my-existing-project
spinbox add --redis --with-examples

# Result:
# redis/
# ├── EXAMPLES.md
# ├── example-caching.js
# ├── example-pub-sub.js
# └── example-sessions.js
```

## Example Structure

Each example follows a consistent structure:

### Python Examples

```python
# example-basic-crud.py
"""
FastAPI CRUD Example

This example demonstrates:
- Basic CRUD operations
- SQLAlchemy integration
- Request/response models
- Error handling
"""

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
# ... imports

app = FastAPI(title="CRUD Example")

# ... implementation

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### TypeScript Examples

```typescript
// example-basic-app.tsx
/**
 * Next.js Basic App Example
 * 
 * This example demonstrates:
 * - Next.js app structure
 * - Component composition
 * - State management
 * - API integration
 */

import React, { useState } from 'react';
import Head from 'next/head';

export default function BasicApp() {
  // ... implementation
}
```

### SQL Examples

```sql
-- example-schema.sql
-- PostgreSQL Schema Example
-- 
-- This example demonstrates:
-- - Table creation
-- - Relationships
-- - Indexes
-- - Constraints

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Documentation Files

Each component includes an `EXAMPLES.md` file with:

### Setup Instructions

```markdown
# FastAPI Examples

## Setup

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Run the database**:
   ```bash
   docker-compose up -d postgres
   ```

## Usage

### Running Examples

Each example can be run independently:

```bash
# Basic CRUD example
python example-basic-crud.py

# Auth example
python example-auth-simple.py

# WebSocket example
python example-websocket.py
```
```

### API Documentation

Examples include API documentation and usage patterns:

```markdown
## API Endpoints

### Users CRUD

- `POST /users/` - Create a new user
- `GET /users/` - List all users
- `GET /users/{id}` - Get a specific user
- `PUT /users/{id}` - Update a user
- `DELETE /users/{id}` - Delete a user

### Example Requests

```bash
# Create a user
curl -X POST "http://localhost:8000/users/" \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# Get all users
curl "http://localhost:8000/users/"
```
```

## Combining with Dependencies

Use both flags together for a complete development setup:

```bash
# Create project with dependencies AND examples
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps --with-examples

# Result:
# - All dependencies added to requirements.txt and package.json
# - Working code examples for all components
# - Installation scripts created
# - Complete documentation and usage instructions
```

## Example Categories

### Learning Examples

- **Basic patterns** - Simple implementations showing core concepts
- **Best practices** - Production-ready patterns and error handling
- **Integration patterns** - How components work together

### Production Examples

- **Authentication** - JWT, OAuth, session management
- **Database operations** - CRUD, migrations, relationships
- **API design** - REST, GraphQL, WebSocket patterns
- **Error handling** - Graceful failures and user feedback

### Advanced Examples

- **Performance optimization** - Caching, connection pooling
- **Monitoring** - Logging, metrics, health checks
- **Security** - Input validation, CORS, rate limiting

## Customization

Examples are designed to be:

1. **Modular** - Each example is self-contained
2. **Extensible** - Easy to modify and build upon
3. **Educational** - Well-commented and documented
4. **Practical** - Based on real-world use cases

## Best Practices

1. **Review examples** before using in production
2. **Understand the patterns** demonstrated in each example
3. **Adapt to your needs** - Examples are starting points
4. **Keep examples updated** as your project evolves
5. **Use as learning resources** for team members

## Troubleshooting

### Common Issues

**Q: Examples not being added**
- Ensure you're using the `--with-examples` flag
- Check that the component supports examples
- Verify the component is being detected correctly

**Q: Example files not executable**
- Some examples may need execute permissions
- Check file permissions and adjust as needed

**Q: Examples don't match project structure**
- Examples are templates - adapt to your project structure
- Use examples as guidance, not strict requirements

### Getting Help

If you encounter issues with examples:

1. **Check EXAMPLES.md** - Each component has usage instructions
2. **Review example code** - Comments explain functionality
3. **Test examples individually** - Isolate issues
4. **Report bugs** - File issues for incorrect examples

## Advanced Usage

### Profile-Based Examples

```bash
# AI/LLM project with specialized examples
spinbox create ai-project --profile ai-llm --with-examples

# Data science project with ML examples
spinbox create data-project --profile data-science --with-examples
```

### Selective Examples

```bash
# Add just the examples you need
spinbox add --fastapi --with-examples     # API examples
spinbox add --nextjs --with-examples      # Frontend examples
spinbox add --postgresql --with-examples  # Database examples
```

### Complex Combinations

```bash
# Full-stack with vector database and AI
spinbox create ai-app --fastapi --nextjs --postgresql --chroma --with-deps --with-examples

# Result:
# - Complete full-stack examples
# - AI/vector database integration
# - All dependencies managed
# - Comprehensive documentation
```

This examples system provides immediate value by giving you working, well-documented code that demonstrates best practices and real-world patterns for each component in your Spinbox project.