# Next.js + FastAPI Integration

Complete examples for building full-stack applications using Next.js frontend with FastAPI backend.

## Overview

This combination demonstrates how to create modern full-stack applications using:
- **Next.js**: React framework for production-ready frontend applications
- **FastAPI**: Modern, fast web framework for building APIs
- **TypeScript**: Type-safe development for both frontend and backend
- **API Integration**: Seamless communication between frontend and backend

## Prerequisites

1. **Node.js 18+**: For Next.js frontend
2. **Python 3.8+**: For FastAPI backend
3. **Dependencies**:
   ```bash
   # Frontend
   npm install next react react-dom typescript @types/react @types/node
   
   # Backend
   pip install fastapi uvicorn python-dotenv pydantic
   ```

## Project Structure

```
project/
├── frontend/                 # Next.js application
│   ├── src/
│   │   ├── pages/
│   │   ├── components/
│   │   ├── lib/
│   │   └── types/
│   ├── public/
│   ├── package.json
│   └── next.config.js
├── backend/                  # FastAPI application
│   ├── app/
│   │   ├── main.py
│   │   ├── routers/
│   │   └── models/
│   ├── requirements.txt
│   └── .env
└── docker-compose.yml       # Development setup
```

## Environment Setup

### Frontend (.env.local)
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=My Full-Stack App
```

### Backend (.env)
```env
# FastAPI Configuration
DEBUG=True
SECRET_KEY=your-secret-key-here
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# Database (if using)
DATABASE_URL=sqlite:///./app.db
```

## Examples Included

### `example-todo-app/`
Complete todo application with CRUD operations.

**Frontend Features:**
- React components with TypeScript
- API client with error handling
- Real-time updates
- Form validation
- Responsive design

**Backend Features:**
- REST API endpoints
- Data validation
- Error handling
- CORS configuration

**Endpoints:**
- `GET /api/todos` - List todos
- `POST /api/todos` - Create todo
- `PUT /api/todos/{id}` - Update todo
- `DELETE /api/todos/{id}` - Delete todo

### `example-auth-app/`
Authentication system with JWT tokens.

**Frontend Features:**
- Login/register forms
- Protected routes
- Token management
- User context
- Logout functionality

**Backend Features:**
- JWT authentication
- Password hashing
- Protected endpoints
- User management
- Session handling

**Endpoints:**
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `GET /auth/me` - Get current user
- `POST /auth/logout` - User logout

### `example-dashboard/`
Real-time dashboard with data visualization.

**Frontend Features:**
- Chart.js integration
- Real-time updates
- Data filtering
- Export functionality
- Responsive design

**Backend Features:**
- WebSocket support
- Data aggregation
- Real-time notifications
- File exports
- Analytics endpoints

**Endpoints:**
- `GET /api/dashboard/stats` - Get statistics
- `WS /ws/dashboard` - Real-time updates
- `GET /api/dashboard/export` - Export data

## API Integration Patterns

### 1. API Client Setup
```typescript
// lib/api.ts
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

class ApiClient {
  private baseURL: string;
  
  constructor(baseURL: string) {
    this.baseURL = baseURL;
  }
  
  async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    const token = localStorage.getItem('token');
    
    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
      ...options,
    };
    
    const response = await fetch(url, config);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return response.json();
  }
  
  get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint);
  }
  
  post<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
  
  put<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }
  
  delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'DELETE',
    });
  }
}

export const apiClient = new ApiClient(API_BASE_URL);
```

### 2. React Hooks for API
```typescript
// hooks/useApi.ts
import { useState, useEffect } from 'react';
import { apiClient } from '@/lib/api';

export function useApi<T>(endpoint: string, dependencies: any[] = []) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);
        const result = await apiClient.get<T>(endpoint);
        setData(result);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred');
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, dependencies);
  
  return { data, loading, error, refetch: () => fetchData() };
}
```

### 3. FastAPI CORS Configuration
```python
# backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app = FastAPI(title="Full-Stack API")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "https://yourdomain.com",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Trusted hosts
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "yourdomain.com"]
)
```

### 4. Type-Safe API Responses
```typescript
// types/api.ts
export interface Todo {
  id: number;
  title: string;
  completed: boolean;
  created_at: string;
  updated_at: string;
}

export interface User {
  id: number;
  email: string;
  name: string;
  created_at: string;
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  per_page: number;
  pages: number;
}
```

## Authentication Integration

### 1. JWT Token Management
```typescript
// hooks/useAuth.ts
import { createContext, useContext, useEffect, useState } from 'react';
import { apiClient } from '@/lib/api';

interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      apiClient.get<User>('/auth/me')
        .then(setUser)
        .catch(() => localStorage.removeItem('token'))
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);
  
  const login = async (email: string, password: string) => {
    const response = await apiClient.post<{ token: string; user: User }>('/auth/login', {
      email,
      password,
    });
    
    localStorage.setItem('token', response.token);
    setUser(response.user);
  };
  
  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };
  
  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

### 2. Protected Routes
```typescript
// components/ProtectedRoute.tsx
import { useAuth } from '@/hooks/useAuth';
import { useRouter } from 'next/router';
import { useEffect } from 'react';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { user, loading } = useAuth();
  const router = useRouter();
  
  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
  }, [user, loading, router]);
  
  if (loading) {
    return <div>Loading...</div>;
  }
  
  if (!user) {
    return null;
  }
  
  return <>{children}</>;
}
```

## Real-time Features

### 1. WebSocket Integration
```typescript
// hooks/useWebSocket.ts
import { useEffect, useState, useRef } from 'react';

export function useWebSocket(url: string) {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [lastMessage, setLastMessage] = useState<any>(null);
  const [readyState, setReadyState] = useState<number>(WebSocket.CONNECTING);
  
  useEffect(() => {
    const ws = new WebSocket(url);
    
    ws.onopen = () => {
      setReadyState(WebSocket.OPEN);
      setSocket(ws);
    };
    
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setLastMessage(data);
    };
    
    ws.onclose = () => {
      setReadyState(WebSocket.CLOSED);
    };
    
    ws.onerror = () => {
      setReadyState(WebSocket.CLOSED);
    };
    
    return () => {
      ws.close();
    };
  }, [url]);
  
  const sendMessage = (message: any) => {
    if (socket && readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(message));
    }
  };
  
  return { lastMessage, readyState, sendMessage };
}
```

### 2. FastAPI WebSocket Handler
```python
# backend/app/websocket.py
from fastapi import WebSocket, WebSocketDisconnect
from typing import List
import json

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)
    
    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/dashboard")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Process message and broadcast
            response = {
                "type": "update",
                "data": message,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            await manager.broadcast(json.dumps(response))
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

## Form Handling

### 1. Form Components
```typescript
// components/TodoForm.tsx
import { useState } from 'react';
import { apiClient } from '@/lib/api';

interface TodoFormProps {
  onSubmit: () => void;
}

export function TodoForm({ onSubmit }: TodoFormProps) {
  const [title, setTitle] = useState('');
  const [loading, setLoading] = useState(false);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim()) return;
    
    setLoading(true);
    
    try {
      await apiClient.post('/api/todos', { title });
      setTitle('');
      onSubmit();
    } catch (error) {
      console.error('Error creating todo:', error);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <input
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Enter todo title"
        className="flex-1 px-3 py-2 border rounded"
        disabled={loading}
      />
      <button
        type="submit"
        disabled={loading || !title.trim()}
        className="px-4 py-2 bg-blue-500 text-white rounded disabled:opacity-50"
      >
        {loading ? 'Adding...' : 'Add Todo'}
      </button>
    </form>
  );
}
```

### 2. Form Validation
```python
# backend/app/schemas.py
from pydantic import BaseModel, validator
from typing import Optional

class TodoCreate(BaseModel):
    title: str
    
    @validator('title')
    def validate_title(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        if len(v) > 200:
            raise ValueError('Title too long')
        return v.strip()

class TodoUpdate(BaseModel):
    title: Optional[str] = None
    completed: Optional[bool] = None
    
    @validator('title')
    def validate_title(cls, v):
        if v is not None and not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip() if v else v
```

## Development Setup

### 1. Docker Compose
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - DEBUG=True
      - CORS_ORIGINS=http://localhost:3000
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Development Scripts
```json
{
  "scripts": {
    "dev": "concurrently \"npm run dev:frontend\" \"npm run dev:backend\"",
    "dev:frontend": "cd frontend && npm run dev",
    "dev:backend": "cd backend && uvicorn app.main:app --reload",
    "build": "cd frontend && npm run build",
    "start": "concurrently \"npm run start:frontend\" \"npm run start:backend\"",
    "start:frontend": "cd frontend && npm start",
    "start:backend": "cd backend && uvicorn app.main:app --host 0.0.0.0 --port 8000"
  }
}
```

## Testing

### 1. Frontend Testing
```typescript
// __tests__/components/TodoForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { TodoForm } from '@/components/TodoForm';

const mockOnSubmit = jest.fn();

describe('TodoForm', () => {
  it('submits form with title', async () => {
    render(<TodoForm onSubmit={mockOnSubmit} />);
    
    const input = screen.getByPlaceholderText('Enter todo title');
    const button = screen.getByText('Add Todo');
    
    fireEvent.change(input, { target: { value: 'Test todo' } });
    fireEvent.click(button);
    
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalled();
    });
  });
});
```

### 2. Backend Testing
```python
# tests/test_todos.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_todo():
    response = client.post("/api/todos", json={"title": "Test todo"})
    assert response.status_code == 201
    
    data = response.json()
    assert data["title"] == "Test todo"
    assert data["completed"] is False
    assert "id" in data

def test_get_todos():
    response = client.get("/api/todos")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
```

## Deployment

### 1. Production Build
```dockerfile
# Frontend Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app

COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["npm", "start"]
```

### 2. Environment Variables
```env
# Production environment
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_APP_NAME=Your App Name

# Backend production
DEBUG=False
SECRET_KEY=your-production-secret-key
CORS_ORIGINS=https://yourdomain.com
DATABASE_URL=postgresql://user:password@db:5432/dbname
```

## Security Considerations

### 1. CORS Configuration
```python
# Strict CORS for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

### 2. API Key Management
```typescript
// Frontend - no API keys in client code
// Use environment variables for public configurations only
const API_URL = process.env.NEXT_PUBLIC_API_URL;
```

### 3. Input Validation
```python
# Backend - validate all inputs
from pydantic import BaseModel, validator

class UserInput(BaseModel):
    data: str
    
    @validator('data')
    def validate_data(cls, v):
        # Sanitize and validate input
        return v.strip()
```

## Performance Optimization

### 1. Next.js Optimization
```typescript
// Image optimization
import Image from 'next/image';

// API route optimization
export async function getServerSideProps() {
  const data = await apiClient.get('/api/data');
  return { props: { data } };
}
```

### 2. FastAPI Optimization
```python
# Response caching
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend

@app.get("/api/data")
@cache(expire=60)
async def get_data():
    return {"data": "cached"}
```

## Next Steps

1. **Start with todo app**: Try the complete CRUD example
2. **Add authentication**: Implement JWT-based auth
3. **Real-time features**: Add WebSocket support
4. **Scale up**: Add database, caching, and monitoring
5. **Deploy**: Use Docker and cloud services

## Resources

- **Next.js Documentation**: https://nextjs.org/docs
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **TypeScript Documentation**: https://www.typescriptlang.org/docs/
- **Full-Stack Deployment**: https://vercel.com/docs