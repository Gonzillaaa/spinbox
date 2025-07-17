# FastAPI Examples

Production-ready FastAPI examples demonstrating common API patterns.

## Examples Included

### `example-basic-crud.py`
Simple CRUD operations for user management.

**Features:**
- Pydantic models for request/response validation
- SQLAlchemy database integration
- Proper HTTP status codes
- Error handling and validation
- OpenAPI documentation

**Setup:**
```bash
pip install fastapi uvicorn sqlalchemy pydantic[email]
uvicorn example-basic-crud:app --reload
```

**Endpoints:**
- `GET /users` - List all users
- `POST /users` - Create new user
- `GET /users/{id}` - Get user by ID
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user

### `example-auth-simple.py`
Basic authentication with JWT tokens.

**Features:**
- User registration and login
- JWT token generation and validation
- Protected routes with dependencies
- Password hashing with bcrypt
- Token refresh mechanism

**Setup:**
```bash
pip install fastapi python-jose[cryptography] passlib[bcrypt]
uvicorn example-auth-simple:app --reload
```

**Endpoints:**
- `POST /register` - Create new account
- `POST /login` - Get access token
- `GET /profile` - Protected route (requires token)
- `POST /refresh` - Refresh access token

### `example-websocket.py`
WebSocket integration for real-time communication.

**Features:**
- WebSocket connection management
- Message broadcasting
- Connection state tracking
- Error handling for disconnections
- JSON message formatting

**Setup:**
```bash
pip install fastapi uvicorn websockets
uvicorn example-websocket:app --reload
```

**Usage:**
- Connect to `ws://localhost:8000/ws`
- Send JSON messages for broadcasting
- Receive real-time updates

## Environment Setup

Create `.env` file:
```env
# Database
DATABASE_URL=postgresql://user:password@localhost/dbname

# Authentication
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
DEBUG=True
```

## API Documentation

After starting the server:
- **Interactive docs**: http://localhost:8000/docs
- **OpenAPI schema**: http://localhost:8000/openapi.json
- **ReDoc**: http://localhost:8000/redoc

## Common Patterns

### Error Handling
```python
from fastapi import HTTPException

@app.get("/users/{user_id}")
def get_user(user_id: int):
    user = get_user_from_db(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Request Validation
```python
from pydantic import BaseModel, validator

class UserCreate(BaseModel):
    name: str
    email: str
    
    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email format')
        return v
```

### Dependency Injection
```python
from fastapi import Depends

def get_current_user(token: str = Depends(oauth2_scheme)):
    # Validate token and return user
    return user

@app.get("/profile")
def get_profile(current_user: User = Depends(get_current_user)):
    return current_user
```

## Common Issues

### Database Connection Error
**Problem**: `Connection refused` or `Database does not exist`
**Solution**: 
- Ensure PostgreSQL is running
- Create database: `createdb your_database_name`
- Check DATABASE_URL format

### Import Errors
**Problem**: `ModuleNotFoundError` for FastAPI or dependencies
**Solution**:
- Install requirements: `pip install -r requirements.txt`
- Use virtual environment: `python -m venv venv && source venv/bin/activate`

### CORS Issues
**Problem**: Frontend can't connect to API
**Solution**: Add CORS middleware:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Performance Tips

- Use async/await for I/O operations
- Implement database connection pooling
- Add caching for frequently accessed data
- Use background tasks for long-running operations
- Implement rate limiting for public APIs

## Security Best Practices

- Always validate user input
- Use environment variables for secrets
- Implement proper authentication
- Add rate limiting and input sanitization
- Use HTTPS in production
- Validate file uploads carefully

## Testing

Run tests with:
```bash
pytest test_examples.py -v
```

Example test structure:
```python
from fastapi.testclient import TestClient
from example_basic_crud import app

client = TestClient(app)

def test_create_user():
    response = client.post("/users", json={"name": "John", "email": "john@example.com"})
    assert response.status_code == 201
    assert response.json()["name"] == "John"
```

## Next Steps

- Check combination examples in `combinations/` directory
- Review AI integration examples in `ai-llm/` directory
- Explore data science integration in `data-science/` directory
- Look at full-stack examples in `combinations/full-stack/`