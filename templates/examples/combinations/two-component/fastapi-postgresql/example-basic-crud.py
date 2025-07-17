"""
FastAPI + PostgreSQL Basic CRUD Example
Complete CRUD operations with SQLAlchemy and PostgreSQL database.

Features:
- User management system
- SQLAlchemy models and relationships
- Database session management
- Input validation with Pydantic
- Error handling
- Pagination support

Setup:
1. pip install fastapi uvicorn sqlalchemy alembic psycopg2-binary python-dotenv
2. Set DATABASE_URL environment variable
3. Run database migrations: alembic upgrade head
4. uvicorn example-basic-crud:app --reload

Environment variables:
- DATABASE_URL: PostgreSQL connection string
- SECRET_KEY: FastAPI secret key
- DEBUG: Enable debug mode (default: True)
"""

from fastapi import FastAPI, HTTPException, Depends, Query
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from sqlalchemy.sql import func
from pydantic import BaseModel, EmailStr, Field, validator
from typing import List, Optional
from datetime import datetime
import os
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is required")

# Create database engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=30,
    pool_recycle=3600
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()

# Database Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    age = Column(Integer)
    bio = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    content = Column(Text)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    is_published = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    author = relationship("User", back_populates="posts")

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models for request/response
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: Optional[int] = Field(None, ge=0, le=120)
    bio: Optional[str] = Field(None, max_length=1000)
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip()
    
    @validator('bio')
    def validate_bio(cls, v):
        if v is not None:
            return v.strip()
        return v

class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    age: Optional[int] = Field(None, ge=0, le=120)
    bio: Optional[str] = Field(None, max_length=1000)
    is_active: Optional[bool] = None
    
    @validator('name')
    def validate_name(cls, v):
        if v is not None and not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip() if v else v

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    age: Optional[int]
    bio: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    post_count: Optional[int] = None
    
    class Config:
        from_attributes = True

class PostCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: Optional[str] = Field(None, max_length=10000)
    is_published: bool = False
    
    @validator('title')
    def validate_title(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip()

class PostUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, max_length=10000)
    is_published: Optional[bool] = None
    
    @validator('title')
    def validate_title(cls, v):
        if v is not None and not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip() if v else v

class PostResponse(BaseModel):
    id: int
    title: str
    content: Optional[str]
    author_id: int
    is_published: bool
    created_at: datetime
    updated_at: datetime
    author: Optional[UserResponse] = None
    
    class Config:
        from_attributes = True

class PaginatedResponse(BaseModel):
    items: List[UserResponse]
    total: int
    page: int
    per_page: int
    pages: int

# FastAPI app
app = FastAPI(
    title="FastAPI + PostgreSQL CRUD",
    description="Complete CRUD operations with SQLAlchemy and PostgreSQL",
    version="1.0.0"
)

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# User CRUD operations
class UserRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, user: UserCreate) -> User:
        # Check if email already exists
        existing_user = self.db.query(User).filter(User.email == user.email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        db_user = User(**user.dict())
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()
    
    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()
    
    def get_all(self, skip: int = 0, limit: int = 100, include_inactive: bool = False) -> List[User]:
        query = self.db.query(User)
        if not include_inactive:
            query = query.filter(User.is_active == True)
        return query.offset(skip).limit(limit).all()
    
    def get_with_post_count(self, skip: int = 0, limit: int = 100) -> List[tuple]:
        return (
            self.db.query(User, func.count(Post.id).label('post_count'))
            .outerjoin(Post)
            .group_by(User.id)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def count(self, include_inactive: bool = False) -> int:
        query = self.db.query(User)
        if not include_inactive:
            query = query.filter(User.is_active == True)
        return query.count()
    
    def update(self, user_id: int, user_update: UserUpdate) -> Optional[User]:
        db_user = self.get_by_id(user_id)
        if not db_user:
            return None
        
        # Check for email conflicts
        if user_update.email and user_update.email != db_user.email:
            existing_user = self.get_by_email(user_update.email)
            if existing_user:
                raise HTTPException(status_code=400, detail="Email already registered")
        
        # Update fields
        update_data = user_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_user, field, value)
        
        db_user.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def delete(self, user_id: int) -> bool:
        db_user = self.get_by_id(user_id)
        if not db_user:
            return False
        
        self.db.delete(db_user)
        self.db.commit()
        return True

# Post CRUD operations
class PostRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, post: PostCreate, author_id: int) -> Post:
        db_post = Post(**post.dict(), author_id=author_id)
        self.db.add(db_post)
        self.db.commit()
        self.db.refresh(db_post)
        return db_post
    
    def get_by_id(self, post_id: int) -> Optional[Post]:
        return self.db.query(Post).filter(Post.id == post_id).first()
    
    def get_by_author(self, author_id: int, skip: int = 0, limit: int = 100) -> List[Post]:
        return (
            self.db.query(Post)
            .filter(Post.author_id == author_id)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def get_published(self, skip: int = 0, limit: int = 100) -> List[Post]:
        return (
            self.db.query(Post)
            .filter(Post.is_published == True)
            .offset(skip)
            .limit(limit)
            .all()
        )
    
    def update(self, post_id: int, post_update: PostUpdate) -> Optional[Post]:
        db_post = self.get_by_id(post_id)
        if not db_post:
            return None
        
        update_data = post_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_post, field, value)
        
        db_post.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(db_post)
        return db_post
    
    def delete(self, post_id: int) -> bool:
        db_post = self.get_by_id(post_id)
        if not db_post:
            return False
        
        self.db.delete(db_post)
        self.db.commit()
        return True

# Dependencies
def get_user_repository(db: Session = Depends(get_db)) -> UserRepository:
    return UserRepository(db)

def get_post_repository(db: Session = Depends(get_db)) -> PostRepository:
    return PostRepository(db)

# Routes
@app.get("/", tags=["root"])
def root():
    """API health check"""
    return {
        "message": "FastAPI + PostgreSQL CRUD API",
        "version": "1.0.0",
        "endpoints": {
            "users": "/users/",
            "posts": "/posts/",
            "health": "/health"
        }
    }

# User endpoints
@app.post("/users/", response_model=UserResponse, status_code=201, tags=["users"])
def create_user(
    user: UserCreate,
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Create a new user"""
    try:
        db_user = user_repo.create(user)
        return UserResponse.from_orm(db_user)
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        raise

@app.get("/users/", response_model=List[UserResponse], tags=["users"])
def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    include_inactive: bool = Query(False),
    with_post_count: bool = Query(False),
    user_repo: UserRepository = Depends(get_user_repository)
):
    """List all users with pagination"""
    if with_post_count:
        users_with_counts = user_repo.get_with_post_count(skip=skip, limit=limit)
        return [
            UserResponse(
                **user.__dict__,
                post_count=post_count
            )
            for user, post_count in users_with_counts
        ]
    else:
        users = user_repo.get_all(skip=skip, limit=limit, include_inactive=include_inactive)
        return [UserResponse.from_orm(user) for user in users]

@app.get("/users/paginated", response_model=PaginatedResponse, tags=["users"])
def get_users_paginated(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    include_inactive: bool = Query(False),
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Get paginated users"""
    skip = (page - 1) * per_page
    users = user_repo.get_all(skip=skip, limit=per_page, include_inactive=include_inactive)
    total = user_repo.count(include_inactive=include_inactive)
    
    return PaginatedResponse(
        items=[UserResponse.from_orm(user) for user in users],
        total=total,
        page=page,
        per_page=per_page,
        pages=(total + per_page - 1) // per_page
    )

@app.get("/users/{user_id}", response_model=UserResponse, tags=["users"])
def get_user(
    user_id: int,
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Get a user by ID"""
    user = user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.from_orm(user)

@app.put("/users/{user_id}", response_model=UserResponse, tags=["users"])
def update_user(
    user_id: int,
    user_update: UserUpdate,
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Update a user"""
    user = user_repo.update(user_id, user_update)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.from_orm(user)

@app.delete("/users/{user_id}", tags=["users"])
def delete_user(
    user_id: int,
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Delete a user"""
    if not user_repo.delete(user_id):
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

# Post endpoints
@app.post("/users/{user_id}/posts/", response_model=PostResponse, status_code=201, tags=["posts"])
def create_post(
    user_id: int,
    post: PostCreate,
    post_repo: PostRepository = Depends(get_post_repository),
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Create a new post for a user"""
    # Check if user exists
    user = user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db_post = post_repo.create(post, user_id)
    return PostResponse.from_orm(db_post)

@app.get("/posts/", response_model=List[PostResponse], tags=["posts"])
def list_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    published_only: bool = Query(False),
    post_repo: PostRepository = Depends(get_post_repository)
):
    """List all posts"""
    if published_only:
        posts = post_repo.get_published(skip=skip, limit=limit)
    else:
        posts = post_repo.get_by_author(0, skip=skip, limit=limit)  # Get all posts
    
    return [PostResponse.from_orm(post) for post in posts]

@app.get("/users/{user_id}/posts/", response_model=List[PostResponse], tags=["posts"])
def get_user_posts(
    user_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    post_repo: PostRepository = Depends(get_post_repository),
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Get all posts by a user"""
    # Check if user exists
    user = user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    posts = post_repo.get_by_author(user_id, skip=skip, limit=limit)
    return [PostResponse.from_orm(post) for post in posts]

@app.get("/posts/{post_id}", response_model=PostResponse, tags=["posts"])
def get_post(
    post_id: int,
    post_repo: PostRepository = Depends(get_post_repository)
):
    """Get a post by ID"""
    post = post_repo.get_by_id(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return PostResponse.from_orm(post)

@app.put("/posts/{post_id}", response_model=PostResponse, tags=["posts"])
def update_post(
    post_id: int,
    post_update: PostUpdate,
    post_repo: PostRepository = Depends(get_post_repository)
):
    """Update a post"""
    post = post_repo.update(post_id, post_update)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return PostResponse.from_orm(post)

@app.delete("/posts/{post_id}", tags=["posts"])
def delete_post(
    post_id: int,
    post_repo: PostRepository = Depends(get_post_repository)
):
    """Delete a post"""
    if not post_repo.delete(post_id):
        raise HTTPException(status_code=404, detail="Post not found")
    return {"message": "Post deleted successfully"}

# Health check
@app.get("/health", tags=["health"])
def health_check(db: Session = Depends(get_db)):
    """Health check endpoint"""
    try:
        # Test database connection
        db.execute("SELECT 1")
        return {
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return {"error": exc.detail, "status_code": exc.status_code}

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unexpected error: {exc}")
    return {"error": "Internal server error", "status_code": 500}

# Run with: uvicorn example-basic-crud:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")