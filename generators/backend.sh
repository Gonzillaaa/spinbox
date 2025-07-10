#!/bin/bash
# Backend component generator for Spinbox
# Creates FastAPI backend with SQLAlchemy, Docker setup, and development tools

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"

# Generate FastAPI backend component
function generate_backend_component() {
    local project_dir="$1"
    local backend_dir="$project_dir/backend"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate FastAPI backend component"
        return 0
    fi
    
    print_status "Creating FastAPI backend component..."
    
    # Ensure backend directory exists
    safe_create_dir "$backend_dir"
    safe_create_dir "$backend_dir/app"
    safe_create_dir "$backend_dir/app/core"
    safe_create_dir "$backend_dir/app/api"
    safe_create_dir "$backend_dir/app/models"
    safe_create_dir "$backend_dir/app/schemas"
    safe_create_dir "$backend_dir/tests"
    
    # Generate backend files
    generate_backend_dockerfiles "$backend_dir"
    generate_backend_requirements "$backend_dir"
    generate_backend_application "$backend_dir"
    generate_backend_database_config "$backend_dir"
    generate_backend_tests "$backend_dir"
    generate_backend_env_files "$backend_dir"
    
    print_status "FastAPI backend component created successfully"
}

# Generate Docker configuration for backend
function generate_backend_dockerfiles() {
    local backend_dir="$1"
    local python_version=$(get_effective_python_version)
    
    # Development Dockerfile
    cat > "$backend_dir/Dockerfile.dev" << EOF
FROM python:${python_version}-slim

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    build-essential \\
    zsh \\
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \\
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Configure Zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\\/powerlevel10k"/g' ~/.zshrc \\
    && sed -i 's/plugins=(git)/plugins=(git docker docker-compose python pip)/g' ~/.zshrc \\
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Set up virtual environment path
ENV PATH="/workspace/venv/bin:\$PATH"

# Add development aliases
RUN echo '# Development aliases' >> ~/.zshrc \\
    && echo 'alias rs="uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"' >> ~/.zshrc \\
    && echo 'alias test="pytest"' >> ~/.zshrc \\
    && echo 'alias uvinstall="uv pip install -r requirements.txt"' >> ~/.zshrc \\
    && echo 'alias migrate="alembic upgrade head"' >> ~/.zshrc

EXPOSE 8000

# Activate virtual environment on shell start
RUN echo 'if [[ -f /workspace/venv/bin/activate ]]; then source /workspace/venv/bin/activate; fi' >> ~/.zshrc

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
EOF

    # Production Dockerfile
    cat > "$backend_dir/Dockerfile" << EOF
FROM python:${python_version}-slim

WORKDIR /app

# Install UV for dependency management
RUN pip install --no-cache-dir uv

# Create and activate virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:\$PATH"

# Copy and install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

# Copy application code
COPY . .

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

    # Docker ignore file
    cat > "$backend_dir/.dockerignore" << 'EOF'
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
.env
.env.local
.pytest_cache/
.coverage
.tox/
dist/
build/
*.egg-info/
.git/
.gitignore
README.md
Dockerfile*
docker-compose*
EOF

    print_debug "Generated backend Docker configuration"
}

# Generate requirements.txt with appropriate dependencies
function generate_backend_requirements() {
    local backend_dir="$1"
    
    cat > "$backend_dir/requirements.txt" << 'EOF'
# FastAPI and ASGI server
fastapi>=0.103.0
uvicorn[standard]>=0.23.0

# Database
sqlalchemy>=2.0.0
alembic>=1.12.0

# PostgreSQL adapter
psycopg2-binary>=2.9.7

# Redis client
redis>=5.0.0

# Data validation and serialization
pydantic>=2.4.0
pydantic-settings>=2.0.0

# Environment management
python-dotenv>=1.0.0

# HTTP client for testing
httpx>=0.24.1

# Testing
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-cov>=4.1.0

# Development tools
black>=23.0.0
isort>=5.12.0
mypy>=1.5.0
EOF

    # Add optional dependencies based on selected components
    if [[ "${USE_MONGODB:-false}" == "true" ]]; then
        cat >> "$backend_dir/requirements.txt" << 'EOF'

# MongoDB dependencies
motor>=3.3.0
beanie>=1.23.0
EOF
    fi
    
    if [[ "${USE_CHROMA:-false}" == "true" ]]; then
        cat >> "$backend_dir/requirements.txt" << 'EOF'

# Vector database dependencies
chromadb>=0.4.0
sentence-transformers>=2.2.0
EOF
    fi

    print_debug "Generated backend requirements.txt"
}

# Generate main FastAPI application structure
function generate_backend_application() {
    local backend_dir="$1"
    local app_dir="$backend_dir/app"
    
    # Main application entry point
    cat > "$app_dir/main.py" << 'EOF'
"""
FastAPI application entry point.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.api_v1.api import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Set up CORS
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": f"Welcome to {settings.PROJECT_NAME} API"}

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": settings.PROJECT_NAME}
EOF

    # Core configuration
    cat > "$app_dir/core/__init__.py" << 'EOF'
"""Core application modules."""
EOF

    cat > "$app_dir/core/config.py" << 'EOF'
"""
Application configuration.
"""
import secrets
from typing import Any, Dict, List, Optional, Union

from pydantic import AnyHttpUrl, field_validator, PostgresDsn, ValidationInfo
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Project"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = secrets.token_urlsafe(32)
    
    # Database
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "app"
    POSTGRES_PORT: int = 5432
    
    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    
    # CORS
    BACKEND_CORS_ORIGINS: List[AnyHttpUrl] = ["http://localhost:3000"]
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    # Database URL construction
    SQLALCHEMY_DATABASE_URI: Optional[PostgresDsn] = None
    
    @field_validator("SQLALCHEMY_DATABASE_URI", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: Optional[str], info: ValidationInfo) -> Any:
        if isinstance(v, str):
            return v
        return PostgresDsn.build(
            scheme="postgresql",
            username=info.data.get("POSTGRES_USER"),
            password=info.data.get("POSTGRES_PASSWORD"),
            host=info.data.get("POSTGRES_SERVER"),
            port=info.data.get("POSTGRES_PORT"),
            path=f"/{info.data.get('POSTGRES_DB') or ''}",
        )

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()
EOF

    # API router
    safe_create_dir "$app_dir/api"
    safe_create_dir "$app_dir/api/api_v1"
    
    cat > "$app_dir/api/__init__.py" << 'EOF'
"""API modules."""
EOF

    cat > "$app_dir/api/api_v1/__init__.py" << 'EOF'
"""API v1 modules."""
EOF

    cat > "$app_dir/api/api_v1/api.py" << 'EOF'
"""
API v1 router.
"""
from fastapi import APIRouter

from app.api.api_v1.endpoints import items

api_router = APIRouter()
api_router.include_router(items.router, prefix="/items", tags=["items"])
EOF

    # Example endpoints
    safe_create_dir "$app_dir/api/api_v1/endpoints"
    cat > "$app_dir/api/api_v1/endpoints/__init__.py" << 'EOF'
"""API endpoints."""
EOF

    cat > "$app_dir/api/api_v1/endpoints/items.py" << 'EOF'
"""
Items endpoints.
"""
from typing import Any, List

from fastapi import APIRouter

router = APIRouter()

@router.get("/", response_model=List[dict])
def read_items() -> Any:
    """
    Retrieve items.
    """
    return [
        {"id": 1, "name": "Item 1", "description": "First item"},
        {"id": 2, "name": "Item 2", "description": "Second item"},
    ]

@router.get("/{item_id}", response_model=dict)
def read_item(item_id: int) -> Any:
    """
    Get item by ID.
    """
    return {"id": item_id, "name": f"Item {item_id}", "description": f"Item with ID {item_id}"}
EOF

    # Models and schemas placeholder
    cat > "$app_dir/models/__init__.py" << 'EOF'
"""Database models."""
EOF

    cat > "$app_dir/schemas/__init__.py" << 'EOF'
"""Pydantic schemas."""
EOF

    print_debug "Generated FastAPI application structure"
}

# Generate database configuration
function generate_backend_database_config() {
    local backend_dir="$1"
    local app_dir="$backend_dir/app"
    
    cat > "$app_dir/core/database.py" << 'EOF'
"""
Database configuration and session management.
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

engine = create_engine(str(settings.SQLALCHEMY_DATABASE_URI), pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

    # Alembic configuration
    cat > "$backend_dir/alembic.ini" << 'EOF'
# A generic, single database configuration.

[alembic]
# path to migration scripts
script_location = alembic

# template used to generate migration file names; The default value is %%(rev)s_%%(slug)s
# Uncomment the line below if you want the files to be prepended with date and time
# file_template = %%(year)d_%%(month).2d_%%(day).2d_%%(hour).2d%%(minute).2d-%%(rev)s_%%(slug)s

# sys.path path, will be prepended to sys.path if present.
# defaults to the current working directory.
prepend_sys_path = .

# timezone to use when rendering the date within the migration file
# as well as the filename.
# If specified, requires the python-dateutil library that can be
# installed by adding `alembic[tz]` to the pip requirements
# string value is passed to dateutil.tz.gettz()
# leave blank for localtime
# timezone =

# max length of characters to apply to the
# "slug" field
# truncate_slug_length = 40

# set to 'true' to run the environment during
# the 'revision' command, regardless of autogenerate
# revision_environment = false

# set to 'true' to allow .pyc and .pyo files without
# a source .py file to be detected as revisions in the
# versions/ directory
# sourceless = false

# version number format (defaults to 4 digits with zero-pad)
version_num_format = %04d

# version_locations = %(here)s/bar:%(here)s/bat:alembic/versions

# version path separator; As mentioned above, this is the character used to split
# version_locations. The default within new alembic.ini files is "os", which uses
# os.pathsep. If this key is omitted entirely, it falls back to the legacy
# behavior of splitting on spaces and/or commas.
# Valid values for version_path_separator are:
#
# version_path_separator = :
# version_path_separator = ;
# version_path_separator = space
version_path_separator = os

# the output encoding used when revision files
# are written from script.py.mako
# output_encoding = utf-8

sqlalchemy.url = driver://user:pass@localhost/dbname


[post_write_hooks]
# post_write_hooks defines scripts or Python functions that are run
# on newly generated revision scripts.  See the documentation for further
# detail and examples

# format using "black" - use the console_scripts runner, against the "black" entrypoint
# hooks = black
# black.type = console_scripts
# black.entrypoint = black
# black.options = -l 79 REVISION_SCRIPT_FILENAME

# Logging configuration
[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
EOF

    print_debug "Generated database configuration"
}

# Generate test files
function generate_backend_tests() {
    local backend_dir="$1"
    local tests_dir="$backend_dir/tests"
    
    cat > "$tests_dir/__init__.py" << 'EOF'
"""Backend tests."""
EOF

    cat > "$tests_dir/conftest.py" << 'EOF'
"""
Test configuration and fixtures.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import get_db, Base

# Test database URL
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    return TestClient(app)
EOF

    cat > "$tests_dir/test_main.py" << 'EOF'
"""
Test main application endpoints.
"""
from fastapi.testclient import TestClient


def test_read_root(client: TestClient):
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data

def test_health_check(client: TestClient):
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_read_items(client: TestClient):
    """Test items endpoint."""
    response = client.get("/api/v1/items/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 0
EOF

    print_debug "Generated backend tests"
}

# Generate environment files
function generate_backend_env_files() {
    local backend_dir="$1"
    
    cat > "$backend_dir/.env.example" << 'EOF'
# Database
POSTGRES_SERVER=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=app
POSTGRES_PORT=5432

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# API
PROJECT_NAME="FastAPI Project"
SECRET_KEY=your-secret-key-here

# CORS
BACKEND_CORS_ORIGINS=http://localhost:3000,http://localhost:8080
EOF

    # Create actual .env if it doesn't exist
    if [[ ! -f "$backend_dir/.env" ]]; then
        cp "$backend_dir/.env.example" "$backend_dir/.env"
    fi

    print_debug "Generated environment files"
}

# Main function to create backend component
function create_backend_component() {
    local project_dir="$1"
    
    print_info "Creating FastAPI backend component in $project_dir"
    
    generate_backend_component "$project_dir"
    
    print_status "FastAPI backend component created successfully!"
    print_info "Next steps:"
    echo "  1. cd $(basename "$project_dir")/backend"
    echo "  2. Set up environment: cp .env.example .env"
    echo "  3. Create virtual environment: python -m venv venv"
    echo "  4. Install dependencies: source venv/bin/activate && uv pip install -r requirements.txt"
    echo "  5. Run development server: uvicorn app.main:app --reload"
}

# Export functions for use by project generator
export -f generate_backend_component create_backend_component
export -f generate_backend_dockerfiles generate_backend_requirements
export -f generate_backend_application generate_backend_database_config
export -f generate_backend_tests generate_backend_env_files