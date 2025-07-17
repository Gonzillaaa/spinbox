"""
Next.js + FastAPI Todo App - Backend
Complete FastAPI backend for a todo application with TypeScript frontend.

Features:
- RESTful API endpoints
- Data validation with Pydantic
- CORS configuration for Next.js
- Error handling
- In-memory database (use PostgreSQL in production)
- API documentation with Swagger

Setup:
1. pip install fastapi uvicorn python-dotenv pydantic
2. uvicorn example-todo-app-backend:app --reload
3. Visit http://localhost:8000/docs for API documentation

Frontend Integration:
- Designed to work with Next.js frontend
- CORS configured for localhost:3000
- JSON API responses
- TypeScript-compatible schemas
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
from typing import List, Optional
from datetime import datetime
import uuid
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
DEBUG = os.getenv("DEBUG", "True").lower() == "true"
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")

# FastAPI app
app = FastAPI(
    title="Todo API",
    description="RESTful API for Next.js Todo Application",
    version="1.0.0",
    debug=DEBUG
)

# CORS configuration for Next.js frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# In-memory database (use PostgreSQL/MongoDB in production)
todos_db = []

# Pydantic models for request/response validation
class TodoCreate(BaseModel):
    title: str
    description: Optional[str] = None
    
    @validator('title')
    def validate_title(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        if len(v) > 200:
            raise ValueError('Title too long (max 200 characters)')
        return v.strip()
    
    @validator('description')
    def validate_description(cls, v):
        if v is not None and len(v) > 1000:
            raise ValueError('Description too long (max 1000 characters)')
        return v.strip() if v else v

class TodoUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    completed: Optional[bool] = None
    
    @validator('title')
    def validate_title(cls, v):
        if v is not None:
            if not v.strip():
                raise ValueError('Title cannot be empty')
            if len(v) > 200:
                raise ValueError('Title too long (max 200 characters)')
            return v.strip()
        return v
    
    @validator('description')
    def validate_description(cls, v):
        if v is not None and len(v) > 1000:
            raise ValueError('Description too long (max 1000 characters)')
        return v.strip() if v else v

class TodoResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    completed: bool
    created_at: datetime
    updated_at: datetime

class TodoListResponse(BaseModel):
    todos: List[TodoResponse]
    total: int
    page: int
    per_page: int
    pages: int

class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

# Utility functions
def find_todo_by_id(todo_id: str) -> Optional[dict]:
    """Find todo by ID"""
    for todo in todos_db:
        if todo["id"] == todo_id:
            return todo
    return None

def create_todo_dict(todo_data: TodoCreate) -> dict:
    """Create todo dictionary from Pydantic model"""
    now = datetime.utcnow()
    return {
        "id": str(uuid.uuid4()),
        "title": todo_data.title,
        "description": todo_data.description,
        "completed": False,
        "created_at": now,
        "updated_at": now
    }

def update_todo_dict(todo: dict, update_data: TodoUpdate) -> dict:
    """Update todo dictionary with new data"""
    update_fields = update_data.dict(exclude_unset=True)
    
    for field, value in update_fields.items():
        if field in todo:
            todo[field] = value
    
    todo["updated_at"] = datetime.utcnow()
    return todo

# API Routes
@app.get("/", tags=["root"])
def root():
    """API root endpoint"""
    return {
        "message": "Todo API for Next.js Frontend",
        "version": "1.0.0",
        "docs": "/docs",
        "endpoints": {
            "todos": "/api/todos",
            "create_todo": "POST /api/todos",
            "get_todo": "GET /api/todos/{id}",
            "update_todo": "PUT /api/todos/{id}",
            "delete_todo": "DELETE /api/todos/{id}"
        }
    }

@app.get("/api/todos", response_model=TodoListResponse, tags=["todos"])
def get_todos(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(10, ge=1, le=100, description="Items per page"),
    completed: Optional[bool] = Query(None, description="Filter by completion status"),
    search: Optional[str] = Query(None, description="Search in title and description")
):
    """Get all todos with pagination and filtering"""
    
    # Apply filters
    filtered_todos = todos_db.copy()
    
    if completed is not None:
        filtered_todos = [todo for todo in filtered_todos if todo["completed"] == completed]
    
    if search:
        search_lower = search.lower()
        filtered_todos = [
            todo for todo in filtered_todos 
            if search_lower in todo["title"].lower() or 
            (todo["description"] and search_lower in todo["description"].lower())
        ]
    
    # Sort by created_at descending (newest first)
    filtered_todos.sort(key=lambda x: x["created_at"], reverse=True)
    
    # Calculate pagination
    total = len(filtered_todos)
    pages = (total + per_page - 1) // per_page
    start_index = (page - 1) * per_page
    end_index = start_index + per_page
    
    # Get page items
    page_todos = filtered_todos[start_index:end_index]
    
    return TodoListResponse(
        todos=[TodoResponse(**todo) for todo in page_todos],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages
    )

@app.post("/api/todos", response_model=TodoResponse, status_code=201, tags=["todos"])
def create_todo(todo_data: TodoCreate):
    """Create a new todo"""
    try:
        new_todo = create_todo_dict(todo_data)
        todos_db.append(new_todo)
        
        return TodoResponse(**new_todo)
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/api/todos/{todo_id}", response_model=TodoResponse, tags=["todos"])
def get_todo(todo_id: str):
    """Get a specific todo by ID"""
    todo = find_todo_by_id(todo_id)
    
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    return TodoResponse(**todo)

@app.put("/api/todos/{todo_id}", response_model=TodoResponse, tags=["todos"])
def update_todo(todo_id: str, update_data: TodoUpdate):
    """Update a specific todo"""
    todo = find_todo_by_id(todo_id)
    
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    try:
        updated_todo = update_todo_dict(todo, update_data)
        return TodoResponse(**updated_todo)
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/api/todos/{todo_id}", response_model=APIResponse, tags=["todos"])
def delete_todo(todo_id: str):
    """Delete a specific todo"""
    todo = find_todo_by_id(todo_id)
    
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    todos_db.remove(todo)
    
    return APIResponse(
        success=True,
        message="Todo deleted successfully",
        data={"id": todo_id}
    )

@app.post("/api/todos/{todo_id}/toggle", response_model=TodoResponse, tags=["todos"])
def toggle_todo(todo_id: str):
    """Toggle todo completion status"""
    todo = find_todo_by_id(todo_id)
    
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    todo["completed"] = not todo["completed"]
    todo["updated_at"] = datetime.utcnow()
    
    return TodoResponse(**todo)

@app.get("/api/todos/stats", tags=["todos"])
def get_todo_stats():
    """Get todo statistics"""
    total_todos = len(todos_db)
    completed_todos = len([todo for todo in todos_db if todo["completed"]])
    pending_todos = total_todos - completed_todos
    
    # Calculate completion rate
    completion_rate = (completed_todos / total_todos * 100) if total_todos > 0 else 0
    
    return {
        "total_todos": total_todos,
        "completed_todos": completed_todos,
        "pending_todos": pending_todos,
        "completion_rate": round(completion_rate, 2)
    }

@app.delete("/api/todos", response_model=APIResponse, tags=["todos"])
def clear_todos(
    completed_only: bool = Query(False, description="Only clear completed todos")
):
    """Clear all todos or only completed ones"""
    if completed_only:
        # Remove only completed todos
        global todos_db
        todos_db = [todo for todo in todos_db if not todo["completed"]]
        message = "Completed todos cleared successfully"
    else:
        # Clear all todos
        todos_db.clear()
        message = "All todos cleared successfully"
    
    return APIResponse(
        success=True,
        message=message
    )

# Health check endpoint
@app.get("/health", tags=["health"])
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "total_todos": len(todos_db),
        "api_version": "1.0.0"
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return {
        "success": False,
        "error": {
            "code": exc.status_code,
            "message": exc.detail,
            "timestamp": datetime.utcnow().isoformat()
        }
    }

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return {
        "success": False,
        "error": {
            "code": 500,
            "message": "Internal server error",
            "timestamp": datetime.utcnow().isoformat()
        }
    }

# Middleware for logging
@app.middleware("http")
async def log_requests(request, call_next):
    import time
    
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    print(f"{request.method} {request.url.path} - {response.status_code} - {process_time:.3f}s")
    
    return response

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize application on startup"""
    print("Todo API starting up...")
    
    # Add some sample data for development
    if DEBUG:
        sample_todos = [
            {
                "id": str(uuid.uuid4()),
                "title": "Learn FastAPI",
                "description": "Complete the FastAPI tutorial and build a REST API",
                "completed": True,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            },
            {
                "id": str(uuid.uuid4()),
                "title": "Build Next.js Frontend",
                "description": "Create a modern React frontend with Next.js",
                "completed": False,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            },
            {
                "id": str(uuid.uuid4()),
                "title": "Deploy to Production",
                "description": "Deploy the full-stack application to cloud",
                "completed": False,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
        ]
        
        todos_db.extend(sample_todos)
        print(f"Added {len(sample_todos)} sample todos for development")
    
    print("Todo API started successfully!")

# Run with: uvicorn example-todo-app-backend:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")