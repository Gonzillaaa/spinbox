"""
FastAPI Simple Authentication Example
Basic authentication with JWT tokens.

Features:
- User registration and login
- JWT token generation and validation
- Protected routes with dependencies
- Password hashing with bcrypt
- Token refresh mechanism

Setup:
1. pip install fastapi uvicorn python-jose[cryptography] passlib[bcrypt]
2. uvicorn example-auth-simple:app --reload
3. Visit http://localhost:8000/docs

Environment variables:
- SECRET_KEY: JWT secret key (default: generated)
- ACCESS_TOKEN_EXPIRE_MINUTES: Token expiration (default: 30)
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional
import os
import secrets

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", secrets.token_urlsafe(32))
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security
security = HTTPBearer()

# In-memory user store (use database in production)
users_db = {}

# Pydantic models
class UserRegister(BaseModel):
    email: EmailStr
    password: str
    name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    expires_in: int

class TokenData(BaseModel):
    email: Optional[str] = None

class User(BaseModel):
    email: EmailStr
    name: str
    created_at: datetime

class UserInDB(User):
    hashed_password: str

# FastAPI app
app = FastAPI(
    title="Authentication API",
    description="Simple authentication with JWT tokens",
    version="1.0.0"
)

# Utility functions
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)

def get_user(email: str) -> Optional[UserInDB]:
    """Get user from database"""
    if email in users_db:
        user_dict = users_db[email]
        return UserInDB(**user_dict)
    return None

def authenticate_user(email: str, password: str) -> Optional[UserInDB]:
    """Authenticate user with email and password"""
    user = get_user(email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """Get current user from JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    
    user = get_user(email=token_data.email)
    if user is None:
        raise credentials_exception
    
    return User(email=user.email, name=user.name, created_at=user.created_at)

# Routes
@app.get("/", tags=["root"])
def read_root():
    """API health check"""
    return {
        "message": "Authentication API is running",
        "docs": "/docs",
        "version": "1.0.0"
    }

@app.post("/register", response_model=User, status_code=status.HTTP_201_CREATED, tags=["auth"])
def register_user(user: UserRegister):
    """Register a new user"""
    # Check if user already exists
    if get_user(user.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists"
        )
    
    # Create user
    hashed_password = get_password_hash(user.password)
    user_dict = {
        "email": user.email,
        "name": user.name,
        "hashed_password": hashed_password,
        "created_at": datetime.utcnow()
    }
    users_db[user.email] = user_dict
    
    return User(email=user.email, name=user.name, created_at=user_dict["created_at"])

@app.post("/login", response_model=Token, tags=["auth"])
def login_user(user: UserLogin):
    """Login user and return JWT token"""
    user_db = authenticate_user(user.email, user.password)
    if not user_db:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_db.email}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )

@app.get("/profile", response_model=User, tags=["users"])
def get_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile (protected route)"""
    return current_user

@app.put("/profile", response_model=User, tags=["users"])
def update_user_profile(
    name: str,
    current_user: User = Depends(get_current_user)
):
    """Update current user profile (protected route)"""
    # Update user in database
    if current_user.email in users_db:
        users_db[current_user.email]["name"] = name
        return User(
            email=current_user.email,
            name=name,
            created_at=current_user.created_at
        )
    
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="User not found"
    )

@app.post("/refresh", response_model=Token, tags=["auth"])
def refresh_token(current_user: User = Depends(get_current_user)):
    """Refresh JWT token (protected route)"""
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": current_user.email}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )

@app.get("/protected", tags=["test"])
def protected_route(current_user: User = Depends(get_current_user)):
    """Example protected route"""
    return {
        "message": f"Hello {current_user.name}!",
        "user_email": current_user.email,
        "access_time": datetime.utcnow()
    }

# Error handlers
@app.exception_handler(401)
def unauthorized_handler(request, exc):
    return {"error": "Unauthorized access"}

@app.exception_handler(422)
def validation_exception_handler(request, exc):
    return {"error": "Validation error", "details": exc.errors()}

# Run with: uvicorn example-auth-simple:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)