"""
FastAPI Basic CRUD Example
Simple user management API demonstrating essential patterns.

Features:
- User creation, reading, updating, deletion
- Pydantic models for validation
- SQLAlchemy database integration
- Proper HTTP status codes
- Error handling

Setup:
1. pip install fastapi uvicorn sqlalchemy pydantic[email]
2. uvicorn example-basic-crud:app --reload
3. Visit http://localhost:8000/docs

Environment variables:
- DATABASE_URL: Database connection string (default: sqlite:///./users.db)
"""

from fastapi import FastAPI, HTTPException, Depends, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import Column, Integer, String, DateTime, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from datetime import datetime
from typing import List, Optional
import os

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./users.db")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database model
class UserDB(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    pass

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None

class UserResponse(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# FastAPI app
app = FastAPI(
    title="User Management API",
    description="Simple CRUD API for user management",
    version="1.0.0"
)

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# CRUD operations
def get_user_by_id(db: Session, user_id: int) -> Optional[UserDB]:
    return db.query(UserDB).filter(UserDB.id == user_id).first()

def get_user_by_email(db: Session, email: str) -> Optional[UserDB]:
    return db.query(UserDB).filter(UserDB.email == email).first()

def create_user(db: Session, user: UserCreate) -> UserDB:
    db_user = UserDB(name=user.name, email=user.email)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: int, user_update: UserUpdate) -> Optional[UserDB]:
    db_user = get_user_by_id(db, user_id)
    if db_user:
        if user_update.name is not None:
            db_user.name = user_update.name
        if user_update.email is not None:
            db_user.email = user_update.email
        db.commit()
        db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: int) -> bool:
    db_user = get_user_by_id(db, user_id)
    if db_user:
        db.delete(db_user)
        db.commit()
        return True
    return False

# Routes
@app.get("/", tags=["root"])
def read_root():
    """API health check"""
    return {
        "message": "User Management API is running",
        "docs": "/docs",
        "version": "1.0.0"
    }

@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED, tags=["users"])
def create_user_endpoint(user: UserCreate, db: Session = Depends(get_db)):
    """Create a new user"""
    # Check if user already exists
    existing_user = get_user_by_email(db, user.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists"
        )
    
    return create_user(db, user)

@app.get("/users", response_model=List[UserResponse], tags=["users"])
def list_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List all users with pagination"""
    users = db.query(UserDB).offset(skip).limit(limit).all()
    return users

@app.get("/users/{user_id}", response_model=UserResponse, tags=["users"])
def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get user by ID"""
    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user

@app.put("/users/{user_id}", response_model=UserResponse, tags=["users"])
def update_user_endpoint(user_id: int, user_update: UserUpdate, db: Session = Depends(get_db)):
    """Update user by ID"""
    # Check if user exists
    existing_user = get_user_by_id(db, user_id)
    if not existing_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if email is already taken by another user
    if user_update.email:
        email_user = get_user_by_email(db, user_update.email)
        if email_user and email_user.id != user_id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already in use by another user"
            )
    
    updated_user = update_user(db, user_id, user_update)
    return updated_user

@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["users"])
def delete_user_endpoint(user_id: int, db: Session = Depends(get_db)):
    """Delete user by ID"""
    if not delete_user(db, user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

@app.get("/users/search/", response_model=List[UserResponse], tags=["users"])
def search_users(q: str, db: Session = Depends(get_db)):
    """Search users by name or email"""
    users = db.query(UserDB).filter(
        (UserDB.name.contains(q)) | (UserDB.email.contains(q))
    ).all()
    return users

# Error handlers
@app.exception_handler(404)
def not_found_handler(request, exc):
    return {"error": "Resource not found"}

@app.exception_handler(422)
def validation_exception_handler(request, exc):
    return {"error": "Validation error", "details": exc.errors()}

# Run with: uvicorn example-basic-crud:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)