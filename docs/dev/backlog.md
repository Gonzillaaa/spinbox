# Spinbox Feature Backlog v0.2+

This document outlines the roadmap for Spinbox extensions, focusing on simplicity and practical value.

## 🎯 Core Philosophy

**Keep Everything Simple**
- Eliminate repetitive tasks (not automate complex workflows)
- Provide real working code (not empty scaffolding)
- Maintain fast execution (< 5 seconds)
- Minimal dependencies

**Security and Environment Best Practices** ✅ **IMPLEMENTED**
- Use virtual environments for Python isolation
- Store secrets in `.env` files (never in code)
- Provide `.env.example` templates for all projects
- Use environment variables for all configuration
- Include proper `.gitignore` for security
- Automatic virtual environment setup with `setup_venv.sh`
- Comprehensive security templates in `templates/security/`

## 🚀 Priority 1: Working Templates (Component-Focused) ✅ **COMPLETED**

### **Goal**: Add working boilerplate code for component combinations

**Current State**: ✅ **IMPLEMENTED** - Components include functional example code  
**Target State**: ✅ **ACHIEVED** - `--with-examples` flag generates working code

### **Implementation Strategy** ✅ **COMPLETED**

#### **New CLI Options** ✅ **IMPLEMENTED**
```bash
# During project creation
spinbox create api --fastapi --postgresql --with-examples
spinbox create webapp --nextjs --fastapi --with-examples

# Adding to existing projects
spinbox add --redis --with-examples
spinbox add --chroma --with-deps --with-examples
```

#### **Recent Completions (Latest)**
- ✅ **Framework generators integration** - Added data-science and ai-ml framework generators with examples support (2025-07-11)
- ✅ **Architectural taxonomy implementation** - 5-tier system: Application/Workflow/Infrastructure/Platform/Foundation
- ✅ **Examples generator enhancement** - Extended support for data-science and ai-ml components
- ✅ **File cleanup** - Removed temporary `verify_fix.sh` script from root directory (2025-07-11)
- ✅ **DRY_RUN variable scoping fix** - Fixed issue where `--dry-run` wasn't properly respected
- ✅ **Test suite simplification** - Reduced complex test dependencies, improved execution speed
- ✅ **Self-contained testing** - All tests now follow CLAUDE.md philosophy
- ✅ **Examples generator implementation** - Full working examples for FastAPI and Next.js
- ✅ **Environment configuration** - Automatic `.env.example` generation

#### **Component Combination Matrix**

**Single Components** (Basic examples):
- `--python --with-examples` → Sample main.py, virtual environment setup
- `--nodejs --with-examples` → Sample app.js, package.json setup
- `--fastapi --with-examples` → Basic API routes, models, main.py
- `--nextjs --with-examples` → Pages, components, API routes
- `--data-science --with-examples` → Jupyter notebooks, data pipeline scripts, analysis workflows
- `--ai-ml --with-examples` → Research agents, document processing, LLM integration

**Two-Component Combinations**:
- `--fastapi --postgresql --with-examples` → FastAPI + SQLAlchemy models, CRUD operations
- `--fastapi --mongodb --with-examples` → FastAPI + Beanie models, document operations
- `--fastapi --redis --with-examples` → FastAPI + Redis caching/queuing examples
- `--fastapi --chroma --with-examples` → FastAPI + vector search endpoints
- `--nextjs --fastapi --with-examples` → Next.js + API client integration
- `--data-science --postgresql --with-examples` → Data analysis workflows with database storage
- `--ai-ml --chroma --with-examples` → AI/ML workflows with vector search capabilities

**Three-Component Combinations**:
- `--fastapi --postgresql --redis --with-examples` → API + DB + caching patterns
- `--fastapi --mongodb --chroma --with-examples` → API + documents + vectors
- `--nextjs --fastapi --postgresql --with-examples` → Full-stack web app

**Complex Combinations**:
- `--nextjs --fastapi --postgresql --redis --with-examples` → Full stack + caching
- `--fastapi --postgresql --mongodb --chroma --with-examples` → Multi-storage API
- `--fastapi --ai-ml --chroma --postgresql --with-examples` → AI API with vector search and data storage
- `--data-science --ai-ml --postgresql --chroma --with-examples` → Complete ML pipeline with data processing and vector search

#### **Example Code Templates**

**FastAPI + PostgreSQL** (`templates/examples/fastapi-postgresql/`):
```python
# schemas.py - Pydantic models for API
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# models.py - SQLAlchemy models
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# crud.py - Database operations with type hints
from sqlalchemy.orm import Session
from typing import Optional
from . import models, schemas

def get_user(db: Session, user_id: int) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_users(db: Session, skip: int = 0, limit: int = 100) -> list[models.User]:
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate) -> models.User:
    db_user = models.User(name=user.name, email=user.email)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# main.py - FastAPI app with proper type hints
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from . import crud, models, schemas
from .database import get_db

app = FastAPI(title="FastAPI + PostgreSQL Example")

@app.get("/users/{user_id}", response_model=schemas.UserResponse)
def read_user(user_id: int, db: Session = Depends(get_db)):
    user = crud.get_user(db, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/users/", response_model=List[schemas.UserResponse])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = crud.get_users(db, skip=skip, limit=limit)
    return users

@app.post("/users/", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    return crud.create_user(db=db, user=user)

# database.py - Database connection with environment variables
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

# Environment variables with secure defaults
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/app_db"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# .env.example - Template for environment variables
# Copy this to .env and fill in your actual values
# Never commit .env to version control!

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/database_name

# Application Settings
DEBUG=True
SECRET_KEY=your-secret-key-here
API_HOST=0.0.0.0
API_PORT=8000

# External Services
REDIS_URL=redis://localhost:6379/0

# .env - Actual environment file (create from .env.example)
# This file should be in .gitignore and never committed!
DATABASE_URL=postgresql://postgres:postgres@postgresql:5432/app_db
DEBUG=True
SECRET_KEY=super-secret-key-change-in-production
API_HOST=0.0.0.0
API_PORT=8000
REDIS_URL=redis://redis:6379/0

# requirements.txt - Updated with environment management
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
sqlalchemy>=2.0.0
asyncpg>=0.29.0
alembic>=1.13.0
python-dotenv>=1.0.0
pydantic-settings>=2.1.0

# main.py - Updated with environment configuration
import os
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseSettings
from . import crud, models, schemas
from .database import get_db, engine

class Settings(BaseSettings):
    app_name: str = "FastAPI + PostgreSQL Example"
    debug: bool = False
    secret_key: str = "change-me-in-production"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    
    class Config:
        env_file = ".env"

settings = Settings()

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    docs_url="/docs" if settings.debug else None
)

# Rest of the FastAPI code remains the same...
```

**Data Science Workflow** (`templates/examples/data-science/`):
```python
# data_pipeline.py - Complete data processing pipeline
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_data(file_path: str) -> pd.DataFrame:
    """Load data from CSV file"""
    try:
        df = pd.read_csv(file_path)
        logger.info(f"Loaded {len(df)} records from {file_path}")
        return df
    except FileNotFoundError:
        logger.error(f"File not found: {file_path}")
        return pd.DataFrame()

def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and preprocess data"""
    df = df.drop_duplicates()
    df = df.fillna(method='ffill')
    
    if 'date' in df.columns:
        df['date'] = pd.to_datetime(df['date'])
    
    logger.info(f"Cleaned data: {len(df)} records remaining")
    return df

def analyze_data(df: pd.DataFrame) -> dict:
    """Perform basic data analysis"""
    if df.empty:
        return {}
    
    analysis = {
        'record_count': len(df),
        'numeric_columns': df.select_dtypes(include=[np.number]).columns.tolist(),
        'categorical_columns': df.select_dtypes(include=['object']).columns.tolist(),
        'missing_values': df.isnull().sum().to_dict(),
        'summary_stats': df.describe().to_dict() if len(df.select_dtypes(include=[np.number]).columns) > 0 else {}
    }
    
    return analysis

def generate_visualizations(df: pd.DataFrame, output_dir: str):
    """Generate and save visualizations"""
    if df.empty:
        return
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    
    if len(numeric_cols) > 0:
        fig, axes = plt.subplots(len(numeric_cols), 1, figsize=(10, 4 * len(numeric_cols)))
        if len(numeric_cols) == 1:
            axes = [axes]
        
        for i, col in enumerate(numeric_cols):
            axes[i].hist(df[col], bins=30, alpha=0.7)
            axes[i].set_title(f'Distribution of {col}')
        
        plt.tight_layout()
        plt.savefig(output_path / 'distributions.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        logger.info(f"Visualizations saved to {output_path}")

def main():
    """Main pipeline execution"""
    logger.info("Starting data pipeline...")
    
    # Generate sample data for demonstration
    np.random.seed(42)
    sample_data = pd.DataFrame({
        'date': pd.date_range('2023-01-01', periods=1000, freq='D'),
        'value': np.cumsum(np.random.randn(1000)) + 100,
        'category': np.random.choice(['A', 'B', 'C'], 1000),
        'amount': np.random.uniform(10, 1000, 1000)
    })
    
    # Process data
    df_clean = clean_data(sample_data)
    analysis = analyze_data(df_clean)
    generate_visualizations(df_clean, "./reports")
    
    logger.info("Pipeline completed successfully!")

if __name__ == "__main__":
    main()
```

**AI/ML Workflow** (`templates/examples/ai-ml/`):
```python
# research_agent.py - AI research agent with LLM integration
import os
import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

try:
    import anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False

class ResearchAgent:
    """AI Agent for conducting research and generating reports"""
    
    def __init__(self, provider: str = "openai", model: str = None):
        self.provider = provider.lower()
        self.model = model or self._get_default_model()
        self.client = self._initialize_client()
        
    def _get_default_model(self) -> str:
        """Get default model based on provider"""
        defaults = {
            "openai": "gpt-4",
            "anthropic": "claude-3-sonnet-20240229"
        }
        return defaults.get(self.provider, "gpt-4")
    
    def _initialize_client(self):
        """Initialize the LLM client"""
        if self.provider == "openai" and OPENAI_AVAILABLE:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable is required")
            return OpenAI(api_key=api_key)
        
        elif self.provider == "anthropic" and ANTHROPIC_AVAILABLE:
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                raise ValueError("ANTHROPIC_API_KEY environment variable is required")
            return anthropic.Anthropic(api_key=api_key)
        
        else:
            raise ValueError(f"Provider {self.provider} not supported or not installed")
    
    def generate_response(self, prompt: str, system_prompt: str = None) -> str:
        """Generate response using configured LLM"""
        try:
            if self.provider == "openai":
                messages = []
                if system_prompt:
                    messages.append({"role": "system", "content": system_prompt})
                messages.append({"role": "user", "content": prompt})
                
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    max_tokens=2000,
                    temperature=0.7
                )
                return response.choices[0].message.content
            
            elif self.provider == "anthropic":
                response = self.client.messages.create(
                    model=self.model,
                    max_tokens=2000,
                    system=system_prompt or "You are a helpful research assistant.",
                    messages=[{"role": "user", "content": prompt}]
                )
                return response.content[0].text
            
        except Exception as e:
            return f"Error generating response: {str(e)}"
    
    def research_topic(self, topic: str, depth: str = "medium") -> Dict[str, Any]:
        """Research a topic and return structured findings"""
        system_prompt = """You are a research assistant. Provide comprehensive, accurate information about the given topic. 
        Structure your response with:
        1. Overview
        2. Key Points (3-5 main points)
        3. Current Trends
        4. Implications
        5. References/Sources to explore further
        
        Be factual and cite your reasoning."""
        
        research_prompt = f"""
        Research the topic: {topic}
        
        Depth level: {depth}
        
        Please provide a comprehensive analysis covering the key aspects, current state, 
        and implications of this topic. Focus on accuracy and practical insights.
        """
        
        response = self.generate_response(research_prompt, system_prompt)
        
        return {
            "topic": topic,
            "depth": depth,
            "timestamp": datetime.now().isoformat(),
            "content": response,
            "agent_info": {
                "provider": self.provider,
                "model": self.model
            }
        }
    
    def save_research(self, research_data: Dict[str, Any], output_dir: str = "../reports"):
        """Save research data to file"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        topic_slug = research_data['topic'].lower().replace(' ', '_').replace('/', '_')
        
        json_file = output_path / f"{topic_slug}_research_{timestamp}.json"
        with open(json_file, 'w') as f:
            json.dump(research_data, f, indent=2)
        
        return str(json_file)

def main():
    """Example usage of the Research Agent"""
    print("🤖 Starting Research Agent Example...")
    
    try:
        if OPENAI_AVAILABLE and os.getenv("OPENAI_API_KEY"):
            agent = ResearchAgent(provider="openai")
        elif ANTHROPIC_AVAILABLE and os.getenv("ANTHROPIC_API_KEY"):
            agent = ResearchAgent(provider="anthropic")
        else:
            print("❌ No API keys found. Please set OPENAI_API_KEY or ANTHROPIC_API_KEY")
            return
    
    except Exception as e:
        print(f"❌ Error initializing agent: {e}")
        return
    
    # Example research topic
    topic = "Artificial Intelligence in Climate Change Solutions"
    
    print(f"🔍 Researching topic: {topic}")
    
    # Conduct research
    research_data = agent.research_topic(topic, depth="medium")
    
    # Save research
    output_file = agent.save_research(research_data)
    
    print(f"✅ Research completed and saved to: {output_file}")

if __name__ == "__main__":
    main()
```

**FastAPI + Redis** (`templates/examples/fastapi-redis/`):
```python
# schemas.py - Pydantic models for Redis operations
from pydantic import BaseModel
from typing import Any, Dict, Optional

class CacheResponse(BaseModel):
    data: Any
    cached: bool = False

class TaskRequest(BaseModel):
    data: str
    priority: Optional[int] = 0

class TaskResponse(BaseModel):
    job_id: str
    status: str

# cache.py - Redis caching decorator with type hints
import os
import redis
import json
from functools import wraps
from typing import Callable, Any
from dotenv import load_dotenv

load_dotenv()

# Environment-based Redis configuration
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_DB = int(os.getenv("REDIS_DB", "0"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", None)

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=REDIS_DB,
    password=REDIS_PASSWORD,
    decode_responses=True
)

def cache_result(expire_time: int = 300):
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            cache_key = f"{func.__name__}:{hash(str(args) + str(kwargs))}"
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
            
            result = func(*args, **kwargs)
            redis_client.setex(cache_key, expire_time, json.dumps(result))
            return result
        return wrapper
    return decorator

# queue.py - Redis queue operations with type hints
from rq import Queue
from redis import Redis
from typing import Callable, Any

redis_conn = Redis(host='redis', port=6379)
queue = Queue(connection=redis_conn)

def enqueue_task(func: Callable, *args: Any, **kwargs: Any) -> str:
    job = queue.enqueue(func, *args, **kwargs)
    return str(job.id)

# main.py - FastAPI app with Redis and proper type hints
from fastapi import FastAPI
from typing import Dict, Any
from .cache import cache_result
from .queue import enqueue_task
from .schemas import CacheResponse, TaskRequest, TaskResponse

app = FastAPI(title="FastAPI + Redis Example")

@app.get("/cached-data", response_model=CacheResponse)
@cache_result(expire_time=600)
def get_cached_data() -> Dict[str, Any]:
    # Expensive operation
    return {"data": "This is cached for 10 minutes"}

@app.post("/async-task", response_model=TaskResponse)
def create_async_task(task: TaskRequest) -> TaskResponse:
    job_id = enqueue_task(process_data, task.data)
    return TaskResponse(job_id=job_id, status="queued")

def process_data(data: str) -> str:
    # Background task processing
    return f"Processed: {data}"
```

**FastAPI + Chroma** (`templates/examples/fastapi-chroma/`):
```python
# vector_store.py - Chroma operations
import chromadb
from chromadb.config import Settings

client = chromadb.Client(Settings(
    persist_directory="./chroma_data",
    anonymized_telemetry=False
))

collection = client.get_or_create_collection(name="documents")

def add_document(doc_id: str, content: str, metadata: dict = None):
    collection.add(
        documents=[content],
        metadatas=[metadata or {}],
        ids=[doc_id]
    )

def search_documents(query: str, n_results: int = 10):
    results = collection.query(
        query_texts=[query],
        n_results=n_results
    )
    return results

# main.py - FastAPI app with vector search
from fastapi import FastAPI
from .vector_store import add_document, search_documents

app = FastAPI(title="FastAPI + Chroma Example")

@app.post("/documents/")
def create_document(doc_id: str, content: str, metadata: dict = None):
    add_document(doc_id, content, metadata)
    return {"message": "Document added", "id": doc_id}

@app.get("/search/")
def search(query: str, limit: int = 10):
    results = search_documents(query, limit)
    return {"query": query, "results": results}
```

**Next.js + FastAPI** (`templates/examples/nextjs-fastapi/`):
```typescript
// types/user.ts - TypeScript interfaces
export interface User {
  id: number;
  name: string;
  email: string;
  created_at: string;
}

export interface UserCreate {
  name: string;
  email: string;
}

export interface ApiError {
  detail: string;
  code?: string;
}

// lib/api.ts - API client with proper error handling and types
import { User, UserCreate, ApiError } from '../types/user';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    if (!response.ok) {
      const error: ApiError = await response.json().catch(() => ({
        detail: 'Network error occurred',
      }));
      throw new Error(error.detail || 'An error occurred');
    }

    return response.json();
  }

  async fetchUsers(): Promise<User[]> {
    return this.request<User[]>('/users/');
  }

  async fetchUser(id: number): Promise<User> {
    return this.request<User>(`/users/${id}`);
  }

  async createUser(userData: UserCreate): Promise<User> {
    return this.request<User>('/users/', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }
}

export const apiClient = new ApiClient(API_BASE_URL);

// hooks/useUsers.ts - Custom hook for user data
import { useState, useEffect } from 'react';
import { User } from '../types/user';
import { apiClient } from '../lib/api';

interface UseUsersResult {
  users: User[];
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function useUsers(): UseUsersResult {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = async (): Promise<void> => {
    try {
      setLoading(true);
      setError(null);
      const data = await apiClient.fetchUsers();
      setUsers(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return { users, loading, error, refetch: fetchUsers };
}

// components/UserList.tsx - Component with proper TypeScript and error handling
import React from 'react';
import { useUsers } from '../hooks/useUsers';
import { User } from '../types/user';

interface UserItemProps {
  user: User;
}

const UserItem: React.FC<UserItemProps> = ({ user }) => (
  <li className="p-2 border-b border-gray-200 last:border-b-0">
    <div className="flex justify-between items-center">
      <div>
        <span className="font-medium">{user.name}</span>
        <span className="text-gray-600 ml-2">{user.email}</span>
      </div>
      <span className="text-sm text-gray-500">
        {new Date(user.created_at).toLocaleDateString()}
      </span>
    </div>
  </li>
);

const UserList: React.FC = () => {
  const { users, loading, error, refetch } = useUsers();

  if (loading) {
    return (
      <div className="flex justify-center items-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-md p-4">
        <div className="flex">
          <div className="flex-shrink-0">
            <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
            </svg>
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-red-800">Error loading users</h3>
            <p className="text-sm text-red-700 mt-1">{error}</p>
            <button
              onClick={refetch}
              className="mt-2 text-sm text-red-600 hover:text-red-500 underline"
            >
              Try again
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white shadow rounded-lg">
      <div className="px-4 py-5 sm:p-6">
        <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">Users</h3>
        {users.length === 0 ? (
          <p className="text-gray-500">No users found.</p>
        ) : (
          <ul className="divide-y divide-gray-200">
            {users.map((user) => (
              <UserItem key={user.id} user={user} />
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};

export default UserList;

// components/UserForm.tsx - Form with validation and proper TypeScript
import React, { useState } from 'react';
import { UserCreate } from '../types/user';
import { apiClient } from '../lib/api';

interface UserFormProps {
  onSuccess?: () => void;
}

const UserForm: React.FC<UserFormProps> = ({ onSuccess }) => {
  const [formData, setFormData] = useState<UserCreate>({
    name: '',
    email: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>): void => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent): Promise<void> => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await apiClient.createUser(formData);
      setFormData({ name: '', email: '' });
      onSuccess?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create user');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
          Name
        </label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleChange}
          required
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          Email
        </label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          required
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      {error && (
        <div className="text-red-600 text-sm">{error}</div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
      >
        {loading ? 'Creating...' : 'Create User'}
      </button>
    </form>
  );
};

export default UserForm;

// pages/index.tsx - Main page with proper TypeScript
import React from 'react';
import Head from 'next/head';
import UserList from '../components/UserList';
import UserForm from '../components/UserForm';
import { useUsers } from '../hooks/useUsers';

const Home: React.FC = () => {
  const { refetch } = useUsers();

  return (
    <>
      <Head>
        <title>Next.js + FastAPI Example</title>
        <meta name="description" content="Example Next.js app with FastAPI backend" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-3xl font-bold text-gray-900 mb-8">
              Next.js + FastAPI Example
            </h1>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Create User</h2>
              <UserForm onSuccess={refetch} />
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Users List</h2>
              <UserList />
            </div>
          </div>
        </div>
      </main>
    </>
  );
};

export default Home;
```

#### **File Structure for Templates**

```
templates/
├── examples/
│   ├── fastapi-postgresql/
│   │   ├── app/
│   │   │   ├── __init__.py
│   │   │   ├── main.py
│   │   │   ├── models.py
│   │   │   ├── schemas.py
│   │   │   ├── crud.py
│   │   │   └── database.py
│   │   ├── requirements.txt
│   │   ├── .env.example
│   │   ├── .env (gitignored)
│   │   ├── .gitignore
│   │   └── setup_venv.sh
│   ├── fastapi-redis/
│   │   ├── app/
│   │   │   ├── __init__.py
│   │   │   ├── main.py
│   │   │   ├── schemas.py
│   │   │   ├── cache.py
│   │   │   └── queue.py
│   │   ├── requirements.txt
│   │   ├── .env.example
│   │   ├── .env (gitignored)
│   │   ├── .gitignore
│   │   └── setup_venv.sh
│   ├── nextjs-fastapi/
│   │   ├── types/
│   │   │   └── user.ts
│   │   ├── lib/
│   │   │   └── api.ts
│   │   ├── components/
│   │   │   ├── UserList.tsx
│   │   │   └── UserForm.tsx
│   │   ├── hooks/
│   │   │   └── useUsers.ts
│   │   ├── pages/
│   │   │   └── index.tsx
│   │   ├── .env.local.example
│   │   ├── .env.local (gitignored)
│   │   ├── .gitignore
│   │   └── package.json
│   └── complex-combinations/
│       ├── fullstack-cached/
│       └── multi-storage/
```

#### **Virtual Environment and Security Setup**

**Python Virtual Environment Setup** (`setup_venv.sh`):
```bash
#!/bin/bash
# Virtual environment setup script for Python projects

set -e

echo "Setting up Python virtual environment..."

# Check if Python 3.12+ is available
if ! command -v python3.12 &> /dev/null; then
    echo "Python 3.12 not found. Please install Python 3.12 or higher."
    exit 1
fi

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3.12 -m venv venv
    echo "Virtual environment created successfully!"
else
    echo "Virtual environment already exists."
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt
    echo "Dependencies installed successfully!"
else
    echo "No requirements.txt found. Installing basic dependencies..."
    pip install fastapi uvicorn python-dotenv
fi

# Create .env file from template if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit .env file with your actual configuration values."
fi

echo "Setup complete!"
echo "To activate the virtual environment, run: source venv/bin/activate"
echo "To start the FastAPI server, run: uvicorn app.main:app --reload"
```

**Python .gitignore Template**:
```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
venv/
env/
ENV/
env.bak/
venv.bak/

# Environment Variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Database
*.db
*.sqlite3

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/

# Dependencies
node_modules/

# Testing
.coverage
.pytest_cache/
.tox/
htmlcov/

# MyPy
.mypy_cache/
.dmypy.json
dmypy.json

# Jupyter Notebook
.ipynb_checkpoints

# Vector Database
chroma_data/
```

**Next.js Environment Setup** (`.env.local.example`):
```bash
# Next.js Environment Variables
# Copy this file to .env.local and fill in your values
# Never commit .env.local to version control!

# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=Next.js + FastAPI Example

# Development Settings
NEXT_PUBLIC_DEBUG=true

# External Services (if needed)
NEXT_PUBLIC_ANALYTICS_ID=your-analytics-id
```

**Next.js .gitignore Template**:
```gitignore
# Dependencies
node_modules/
/.pnp
.pnp.js

# Testing
/coverage

# Next.js
/.next/
/out/

# Production
/build

# Environment Variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Vercel
.vercel

# TypeScript
*.tsbuildinfo
next-env.d.ts

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/
```

#### **Implementation Details**

**New Files to Create**:
- `lib/examples-generator.sh` - Core example generation logic
- `lib/environment-setup.sh` - Virtual environment and security setup
- `templates/examples/` - Directory with all example code
- `templates/security/` - `.gitignore` and `.env.example` templates
- Update all component generators to support `--with-examples`

**Environment Setup Integration**:
```bash
# lib/environment-setup.sh
function setup_python_environment() {
    local project_dir="$1"
    
    # Copy virtual environment setup script
    cp "$TEMPLATES_DIR/security/setup_venv.sh" "$project_dir/"
    chmod +x "$project_dir/setup_venv.sh"
    
    # Copy .gitignore template
    cp "$TEMPLATES_DIR/security/python.gitignore" "$project_dir/.gitignore"
    
    # Copy .env.example template
    cp "$TEMPLATES_DIR/security/python.env.example" "$project_dir/.env.example"
    
    print_info "Python environment setup completed"
    print_info "Run './setup_venv.sh' to create virtual environment"
}

function setup_nextjs_environment() {
    local project_dir="$1"
    
    # Copy .gitignore template
    cp "$TEMPLATES_DIR/security/nextjs.gitignore" "$project_dir/.gitignore"
    
    # Copy .env.local.example template
    cp "$TEMPLATES_DIR/security/nextjs.env.example" "$project_dir/.env.local.example"
    
    print_info "Next.js environment setup completed"
    print_info "Copy .env.local.example to .env.local and configure"
}
```

**Security Best Practices Integration**:
- All Python projects get virtual environment setup scripts
- All projects get comprehensive `.gitignore` files
- All projects get `.env.example` templates
- Environment variables used throughout all examples
- Clear separation between development and production configs
- Secrets never committed to version control

**Component Generator Updates**:
```bash
# In generators/fastapi.sh
function generate_fastapi_examples() {
    local project_dir="$1"
    local fastapi_dir="$project_dir/fastapi"
    
    # Copy base FastAPI examples
    cp -r "$EXAMPLES_DIR/fastapi-basic/"* "$fastapi_dir/"
    
    # Add component-specific examples
    if [[ "$USE_POSTGRESQL" == true ]]; then
        cp -r "$EXAMPLES_DIR/fastapi-postgresql/"* "$fastapi_dir/"
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        cp -r "$EXAMPLES_DIR/fastapi-redis/"* "$fastapi_dir/"
    fi
    
    if [[ "$USE_CHROMA" == true ]]; then
        cp -r "$EXAMPLES_DIR/fastapi-chroma/"* "$fastapi_dir/"
    fi
}
```

---

## 🎯 Priority 2: Simple Dependency Management ✅ **COMPLETED**

### **Goal**: Automatically install and configure dependencies with boilerplate

**Current State**: ✅ **IMPLEMENTED** - Dependencies automatically added when components are created  
**Target State**: ✅ **ACHIEVED** - `--with-deps` flag manages dependencies automatically

### **Implementation Strategy** ✅ **COMPLETED**

#### **Clear Option Separation** ✅ **IMPLEMENTED**
- `--with-deps` → Adds packages to requirements.txt/package.json
- `--with-examples` → Adds starter project templates
- Can be used independently or together

#### **Usage Examples** ✅ **WORKING**
```bash
# Add component with dependencies only
spinbox add --chroma --with-deps
# Result: chromadb added to requirements.txt

# Add component with examples only  
spinbox add --chroma --with-examples
# Result: vector_store.py example added

# Add component with both
spinbox add --chroma --with-deps --with-examples
# Result: chromadb in requirements.txt + vector_store.py example
```

#### **Recent Completions (Latest)**
- ✅ **Dependency manager implementation** - Full `lib/dependency-manager.sh` module
- ✅ **UV integration** - Python projects use UV for modern dependency management
- ✅ **NPM integration** - Node.js projects use NPM for dependency management
- ✅ **Project initialization** - Automatic Python/Node.js project setup
- ✅ **Component dependency mapping** - All components have proper dependency definitions

#### **Dependency Mappings**

**FastAPI Dependencies**:
```toml
[dependencies.fastapi]
packages = [
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "pydantic>=2.5.0"
]
```

**PostgreSQL Dependencies**:
```toml
[dependencies.postgresql]
packages = [
    "sqlalchemy>=2.0.0",
    "asyncpg>=0.29.0",
    "alembic>=1.13.0"
]
```

**Redis Dependencies**:
```toml
[dependencies.redis]
packages = [
    "redis>=5.0.0",
    "celery>=5.3.0"  # Optional for background tasks
]
```

**Chroma Dependencies**:
```toml
[dependencies.chroma]
packages = [
    "chromadb>=0.4.0",
    "sentence-transformers>=2.2.0"
]
```

**MongoDB Dependencies**:
```toml
[dependencies.mongodb]
packages = [
    "beanie>=1.24.0",
    "motor>=3.3.0"
]
```

**Data Science Dependencies**:
```toml
[dependencies.data_science]
packages = [
    "pandas>=2.1.0",
    "numpy>=1.25.0",
    "matplotlib>=3.8.0",
    "seaborn>=0.13.0",
    "jupyter>=1.0.0",
    "jupyterlab>=4.0.0",
    "scikit-learn>=1.3.0",
    "plotly>=5.17.0"
]
```

**AI/ML Dependencies**:
```toml
[dependencies.ai_ml]
packages = [
    "openai>=1.3.0",
    "anthropic>=0.7.0",
    "langchain>=0.0.350",
    "langchain-community>=0.0.1",
    "llama-index>=0.9.0",
    "chromadb>=0.4.0",
    "sentence-transformers>=2.2.0",
    "transformers>=4.36.0",
    "tiktoken>=0.5.0"
]
```

**Next.js Dependencies**:
```json
{
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
```

#### **LLM-Specific Dependencies**

**AI/LLM Profile Enhancements**:
```toml
[dependencies.llm]
packages = [
    # Core LLM packages
    "openai>=1.3.0",
    "anthropic>=0.7.0",
    
    # Framework packages
    "llamaindex>=0.9.0",
    "langchain>=0.0.350",
    "langchain-community>=0.0.1",
    
    # Utility packages
    "tiktoken>=0.5.0",
    "transformers>=4.36.0",
    "torch>=2.1.0"
]
```

**LLM Boilerplate Examples**:
```python
# llm_client.py - LLM client setup
import openai
from anthropic import Anthropic
from llama_index import VectorStoreIndex, SimpleDirectoryReader
from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationChain
from langchain.memory import ConversationBufferMemory

class LLMClient:
    def __init__(self):
        self.openai = openai.OpenAI()
        self.anthropic = Anthropic()
        self.chat_model = ChatOpenAI(temperature=0.7)
        self.memory = ConversationBufferMemory()
        self.conversation = ConversationChain(
            llm=self.chat_model,
            memory=self.memory
        )
    
    def chat_openai(self, message: str):
        response = self.openai.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": message}]
        )
        return response.choices[0].message.content
    
    def chat_anthropic(self, message: str):
        response = self.anthropic.messages.create(
            model="claude-3-sonnet-20240229",
            max_tokens=1000,
            messages=[{"role": "user", "content": message}]
        )
        return response.content[0].text
    
    def index_documents(self, directory: str):
        documents = SimpleDirectoryReader(directory).load_data()
        index = VectorStoreIndex.from_documents(documents)
        return index.as_query_engine()

# main.py - FastAPI app with LLM integration
from fastapi import FastAPI
from .llm_client import LLMClient

app = FastAPI(title="AI/LLM API Example")
llm_client = LLMClient()

@app.post("/chat/openai")
def chat_openai(message: str):
    response = llm_client.chat_openai(message)
    return {"response": response}

@app.post("/chat/anthropic")
def chat_anthropic(message: str):
    response = llm_client.chat_anthropic(message)
    return {"response": response}

@app.post("/query/documents")
def query_documents(query: str):
    # Assumes documents are indexed
    query_engine = llm_client.index_documents("./documents")
    response = query_engine.query(query)
    return {"query": query, "response": str(response)}
```

#### **Implementation Details**

**New Files to Create**:
- `lib/dependency-manager.sh` - Dependency management logic
- `templates/dependencies/` - Component dependency mappings
- Update all component generators to support `--with-deps`

**Dependency Manager Functions**:
```bash
# lib/dependency-manager.sh
function add_python_dependencies() {
    local project_dir="$1"
    local component="$2"
    local requirements_file="$project_dir/requirements.txt"
    
    case "$component" in
        "fastapi")
            add_to_requirements "$requirements_file" "fastapi>=0.104.0"
            add_to_requirements "$requirements_file" "uvicorn[standard]>=0.24.0"
            ;;
        "postgresql")
            add_to_requirements "$requirements_file" "sqlalchemy>=2.0.0"
            add_to_requirements "$requirements_file" "asyncpg>=0.29.0"
            ;;
        "redis")
            add_to_requirements "$requirements_file" "redis>=5.0.0"
            ;;
        "chroma")
            add_to_requirements "$requirements_file" "chromadb>=0.4.0"
            ;;
        "mongodb")
            add_to_requirements "$requirements_file" "beanie>=1.24.0"
            ;;
        "llm")
            add_to_requirements "$requirements_file" "openai>=1.3.0"
            add_to_requirements "$requirements_file" "llamaindex>=0.9.0"
            add_to_requirements "$requirements_file" "langchain>=0.0.350"
            ;;
    esac
}

function add_to_requirements() {
    local requirements_file="$1"
    local package="$2"
    
    # Check if package already exists
    if ! grep -q "^${package%%>=*}" "$requirements_file" 2>/dev/null; then
        echo "$package" >> "$requirements_file"
        print_info "Added $package to requirements.txt"
    fi
}
```

---

## 🎯 Priority 3: Git Hooks Integration

### **Goal**: Add quality gates without complexity

**Current State**: No automated quality checks  
**Target State**: Simple, opinionated git hooks for common quality checks

### **Implementation Strategy**

#### **Simple Hook Types**
```bash
# Basic hooks
spinbox hooks add --pre-commit              # black, isort formatting
spinbox hooks add --pre-push                # pytest tests
spinbox hooks add --security                # bandit security scan

# With examples
spinbox hooks add --pre-commit --with-examples    # Sample .pre-commit-config.yaml
```

#### **Hook Templates**

**Pre-commit Hook** (`.pre-commit-config.yaml`):
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
        language_version: python3.12

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
        args: [--max-line-length=88, --extend-ignore=E203]
```

**Pre-push Hook** (`.git/hooks/pre-push`):
```bash
#!/bin/bash
# Pre-push hook for running tests

echo "Running tests before push..."
python -m pytest tests/ --tb=short
if [ $? -ne 0 ]; then
    echo "Tests failed. Push aborted."
    exit 1
fi

echo "Tests passed. Proceeding with push."
```

**Security Hook** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash
# Security scan hook

echo "Running security scan..."
bandit -r . -f json -o bandit-report.json
if [ $? -ne 0 ]; then
    echo "Security issues found. Commit aborted."
    exit 1
fi

echo "Security scan passed."
```

#### **Implementation Details**

**New Files to Create**:
- `lib/git-hooks.sh` - Git hook management
- `templates/hooks/` - Hook templates
- Add hooks command to `bin/spinbox`

---

## 🎯 Priority 4: Cloud Deployment Helpers

### **Goal**: Simple, step-by-step deployment assistance

**Current State**: No deployment support  
**Target State**: Guided deployment to popular platforms

### **Implementation Strategy**

#### **Platform Support**
```bash
# Interactive deployment setup
spinbox deploy --setup vercel     # Walks through Vercel setup
spinbox deploy --setup railway    # Walks through Railway setup
spinbox deploy --setup aws        # Walks through AWS setup
spinbox deploy --setup gcp        # Walks through GCP setup
```

#### **Platform-Specific Logic**

**Vercel** (Next.js projects):
```bash
# Detects Next.js project
# Generates vercel.json
# Provides deployment commands
```

**Railway** (Full-stack projects):
```bash
# Detects FastAPI + PostgreSQL
# Generates railway.json
# Provides deployment commands
```

**AWS** (Complex projects):
```bash
# Generates basic Docker Compose for ECS
# Provides step-by-step AWS setup
```

**GCP** (Data science / AI projects):
```bash
# Generates Cloud Run configuration
# Provides GCP deployment steps
```

#### **Implementation Details**

**New Files to Create**:
- `lib/deploy-helpers.sh` - Deployment logic
- `templates/deploy/` - Platform-specific configs
- Add deploy command to `bin/spinbox`

---

## 📋 Implementation Timeline

### **Phase 1 (v0.2.0) - Working Templates**
- **Week 1-2**: Create example templates for all component combinations
- **Week 3**: Implement `--with-examples` flag
- **Week 4**: Testing and documentation

### **Phase 2 (v0.3.0) - Dependency Management**
- **Week 1**: Implement `--with-deps` flag
- **Week 2**: Create dependency mappings
- **Week 3**: LLM-specific enhancements
- **Week 4**: Testing and integration

### **Phase 3 (v0.4.0) - Git Hooks**
- **Week 1**: Implement basic hooks
- **Week 2**: Create hook templates
- **Week 3**: Testing and documentation

### **Phase 4 (v0.5.0) - Cloud Deployment**
- **Week 1-2**: Implement platform detection
- **Week 3**: Create deployment helpers
- **Week 4**: Testing and documentation

---

## 🎯 Success Metrics

**Technical Metrics**:
- Time to working project: < 2 minutes
- Generated code compiles and runs without errors
- All component combinations have functional examples

**User Experience Metrics**:
- Reduction in manual configuration steps
- Time from project creation to first API call
- User adoption rate of new features

**Quality Metrics**:
- All generated code follows best practices
- Examples are production-ready patterns
- Documentation is comprehensive and accurate

---

## 🚫 Explicitly Out of Scope

These features are intentionally excluded to maintain simplicity:

- **Team collaboration features** (too complex)
- **Multi-environment syncing** (over-engineering)
- **AI-powered code generation** (complexity creep)
- **Custom DSL or configuration language** (YAML/TOML is sufficient)
- **Package manager replacement** (UV and npm work fine)
- **IDE plugins** (separate project scope)
- **Monitoring/observability** (too many choices)
- **Database migration tools** (Alembic exists)
- **Test framework integration** (pytest is standard)

---

## 🔧 Recent Quality Improvements ✅ **COMPLETED**

### **Development Process Improvements**
- ✅ **CLAUDE.md update** - Emphasized mandatory development cycle with clear rules
- ✅ **Test suite simplification** - Reduced from 19 complex tests to 6 essential tests
- ✅ **Self-contained testing** - Removed external dependencies, improved execution speed
- ✅ **DRY_RUN variable scoping** - Fixed critical issue where dry-run mode wasn't working
- ✅ **File cleanup** - Removed test files from root directory following project structure

### **Code Quality Standards**
- ✅ **Testing philosophy enforcement** - All tests now follow CLAUDE.md simplicity rules
- ✅ **Development cycle documentation** - Clear mandatory workflow for all changes
- ✅ **Atomic commit workflow** - Proper Git workflow with feature branches
- ✅ **Variable scoping fixes** - Proper export/import of environment variables
- ✅ **File management** - Cleaned up temporary verification scripts from root directory

### **Next Steps for Future Work**
- **Always start with feature branches** for major changes
- **Follow atomic commit workflow** consistently
- **Keep test suite simple** (6-9 tests per file maximum)
- **Update documentation** before/during implementation
- **Run tests** before every commit

---

*This backlog represents the focused, practical evolution of Spinbox while maintaining its core philosophy of simplicity and speed.*