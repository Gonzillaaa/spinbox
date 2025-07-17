# FastAPI + PostgreSQL Integration

Complete examples for building database-driven APIs using FastAPI and PostgreSQL.

## Overview

This combination demonstrates how to create production-ready APIs with database persistence using:
- **FastAPI**: Modern, fast web framework for building APIs
- **PostgreSQL**: Powerful, open-source relational database
- **SQLAlchemy**: Python ORM for database interactions
- **Alembic**: Database migration tool

## Prerequisites

1. **PostgreSQL Database**: Running PostgreSQL instance
2. **Dependencies**:
   ```bash
   pip install fastapi uvicorn sqlalchemy alembic psycopg2-binary python-dotenv
   ```

## Database Setup

### Docker PostgreSQL (Recommended)
```bash
docker run --name postgres-db \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  -d postgres:15
```

### Environment Setup
Create `.env` file:
```env
# Database Configuration
DATABASE_URL=postgresql://myuser:mypassword@localhost:5432/myapp
POSTGRES_SERVER=localhost
POSTGRES_PORT=5432
POSTGRES_DB=myapp
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword

# FastAPI Configuration
SECRET_KEY=your-secret-key-here
DEBUG=True
```

## Examples Included

### `example-basic-crud.py`
Complete CRUD operations with SQLAlchemy models.

**Features:**
- User management system
- SQLAlchemy models and relationships
- Database session management
- Input validation with Pydantic
- Error handling

**Endpoints:**
- `POST /users/` - Create user
- `GET /users/` - List users
- `GET /users/{user_id}` - Get user by ID
- `PUT /users/{user_id}` - Update user
- `DELETE /users/{user_id}` - Delete user

### `example-advanced-queries.py`
Advanced database queries and operations.

**Features:**
- Complex queries with joins
- Filtering and pagination
- Aggregation functions
- Raw SQL queries
- Query optimization

**Endpoints:**
- `GET /users/search` - Search users with filters
- `GET /users/stats` - User statistics
- `GET /posts/by-user/{user_id}` - Posts by user
- `GET /analytics/dashboard` - Analytics dashboard

### `example-migrations.py`
Database migrations and schema management.

**Features:**
- Alembic integration
- Migration generation
- Schema versioning
- Database seeding
- Rollback support

**Commands:**
- Generate migrations
- Apply migrations
- Rollback migrations
- Seed database

## Usage Examples

### 1. Create a User
```bash
curl -X POST "http://localhost:8000/users/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30
  }'
```

### 2. List Users with Pagination
```bash
curl "http://localhost:8000/users/?skip=0&limit=10"
```

### 3. Search Users
```bash
curl "http://localhost:8000/users/search?name=John&min_age=25"
```

### 4. Get User Statistics
```bash
curl "http://localhost:8000/users/stats"
```

### 5. Update User
```bash
curl -X PUT "http://localhost:8000/users/1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "email": "john.smith@example.com",
    "age": 31
  }'
```

## Database Models

### User Model
```python
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    age = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    posts = relationship("Post", back_populates="author")
```

### Post Model
```python
class Post(Base):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text)
    author_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    author = relationship("User", back_populates="posts")
```

## Database Patterns

### 1. Repository Pattern
```python
class UserRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, user: UserCreate) -> User:
        db_user = User(**user.dict())
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()
```

### 2. Service Layer
```python
class UserService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo
    
    def create_user(self, user_data: UserCreate) -> UserResponse:
        # Business logic here
        user = self.user_repo.create(user_data)
        return UserResponse.from_orm(user)
```

### 3. Dependency Injection
```python
def get_user_service(db: Session = Depends(get_db)):
    user_repo = UserRepository(db)
    return UserService(user_repo)

@app.post("/users/", response_model=UserResponse)
def create_user(
    user: UserCreate,
    user_service: UserService = Depends(get_user_service)
):
    return user_service.create_user(user)
```

## Advanced Features

### 1. Database Transactions
```python
@app.post("/users/batch")
def create_users_batch(users: List[UserCreate], db: Session = Depends(get_db)):
    try:
        db_users = []
        for user_data in users:
            db_user = User(**user_data.dict())
            db.add(db_user)
            db_users.append(db_user)
        
        db.commit()
        for user in db_users:
            db.refresh(user)
        
        return db_users
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
```

### 2. Connection Pooling
```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True,
    pool_recycle=3600
)
```

### 3. Query Optimization
```python
# Eager loading to avoid N+1 queries
def get_users_with_posts(db: Session):
    return db.query(User).options(joinedload(User.posts)).all()

# Indexing for better performance
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)  # Indexed
    name = Column(String, index=True)  # Indexed for search
```

### 4. Database Migrations
```python
# Generate migration
alembic revision --autogenerate -m "Add user table"

# Apply migration
alembic upgrade head

# Rollback migration
alembic downgrade -1
```

## Security Considerations

### 1. SQL Injection Prevention
```python
# Good: Using ORM
users = db.query(User).filter(User.name == user_name).all()

# Good: Parameterized queries
result = db.execute(text("SELECT * FROM users WHERE name = :name"), {"name": user_name})

# Bad: String concatenation
# query = f"SELECT * FROM users WHERE name = '{user_name}'"  # DON'T DO THIS
```

### 2. Database Credentials
```python
# Use environment variables
DATABASE_URL = os.getenv("DATABASE_URL")

# Never hardcode credentials
# DATABASE_URL = "postgresql://user:password@localhost/db"  # DON'T DO THIS
```

### 3. Input Validation
```python
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(..., ge=0, le=120)
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip()
```

## Performance Optimization

### 1. Database Indexes
```sql
-- Create indexes for frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_created_at ON posts(created_at);
```

### 2. Query Optimization
```python
# Use select_from for complex queries
def get_user_post_count(db: Session):
    return db.query(
        User.id,
        User.name,
        func.count(Post.id).label('post_count')
    ).select_from(User).outerjoin(Post).group_by(User.id).all()

# Use pagination for large datasets
def get_users_paginated(db: Session, skip: int = 0, limit: int = 100):
    return db.query(User).offset(skip).limit(limit).all()
```

### 3. Connection Management
```python
# Use connection pooling
from sqlalchemy.pool import StaticPool

engine = create_engine(
    DATABASE_URL,
    poolclass=StaticPool,
    pool_size=10,
    max_overflow=20
)
```

## Testing

### 1. Test Database Setup
```python
# conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

TEST_DATABASE_URL = "postgresql://test:test@localhost/test_db"

@pytest.fixture
def db_session():
    engine = create_engine(TEST_DATABASE_URL)
    SessionLocal = sessionmaker(bind=engine)
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        # Drop tables
        Base.metadata.drop_all(bind=engine)
```

### 2. API Testing
```python
def test_create_user(client, db_session):
    user_data = {
        "name": "Test User",
        "email": "test@example.com",
        "age": 25
    }
    
    response = client.post("/users/", json=user_data)
    assert response.status_code == 201
    
    data = response.json()
    assert data["name"] == user_data["name"]
    assert data["email"] == user_data["email"]
```

## Deployment

### 1. Environment Variables
```bash
# Production environment
DATABASE_URL=postgresql://user:password@prod-db:5432/myapp
SECRET_KEY=production-secret-key
DEBUG=False
```

### 2. Docker Configuration
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 3. Database Migrations in Production
```bash
# Apply migrations before starting the app
alembic upgrade head

# Start the application
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Monitoring

### 1. Database Metrics
```python
from sqlalchemy import event

@event.listens_for(Engine, "before_cursor_execute")
def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    context._query_start_time = time.time()

@event.listens_for(Engine, "after_cursor_execute")
def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - context._query_start_time
    logger.info(f"Query took {total:.4f}s: {statement[:100]}...")
```

### 2. Health Checks
```python
@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        # Test database connection
        db.execute(text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}
```

## Common Issues and Solutions

### 1. Connection Pool Exhaustion
**Problem**: Too many database connections
**Solution**: Configure connection pooling properly

### 2. Slow Queries
**Problem**: Queries taking too long
**Solution**: Add appropriate indexes and optimize queries

### 3. Migration Conflicts
**Problem**: Multiple developers creating conflicting migrations
**Solution**: Use proper branching strategy and resolve conflicts

### 4. Memory Usage
**Problem**: High memory consumption
**Solution**: Use pagination and limit result sets

## Next Steps

1. **Start with basic CRUD**: Try `example-basic-crud.py`
2. **Add advanced queries**: Implement `example-advanced-queries.py`
3. **Set up migrations**: Use `example-migrations.py`
4. **Add monitoring**: Implement logging and metrics
5. **Deploy**: Use Docker and environment variables

## Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **SQLAlchemy Documentation**: https://docs.sqlalchemy.org/
- **Alembic Documentation**: https://alembic.sqlalchemy.org/
- **FastAPI Database Guide**: https://fastapi.tiangolo.com/tutorial/sql-databases/