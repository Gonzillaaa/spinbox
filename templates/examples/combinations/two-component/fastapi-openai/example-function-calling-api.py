"""
FastAPI + OpenAI Function Calling API Example
RESTful API for AI function calling with tool integration using FastAPI and OpenAI.

Features:
- Function definition and registration
- Tool execution with AI
- Structured outputs
- Multiple function support
- Result validation
- Error handling

Setup:
1. pip install fastapi uvicorn openai python-dotenv pydantic slowapi
2. Set OPENAI_API_KEY environment variable
3. uvicorn example-function-calling-api:app --reload

Environment variables:
- OPENAI_API_KEY: Your OpenAI API key
- OPENAI_MODEL: Model to use (default: gpt-4)
- SECRET_KEY: FastAPI secret key
- RATE_LIMIT_PER_MINUTE: Rate limit (default: 60)
"""

from fastapi import FastAPI, HTTPException, Depends, Request, BackgroundTasks
from pydantic import BaseModel, validator
from typing import List, Dict, Any, Optional, Callable
import os
import json
import time
import math
import random
from datetime import datetime, timedelta
from openai import OpenAI
from dotenv import load_dotenv
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import logging
import inspect

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# FastAPI app
app = FastAPI(
    title="Function Calling API",
    description="OpenAI-powered function calling API with FastAPI",
    version="1.0.0"
)

# Add rate limiter to app
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Configuration
class Settings:
    def __init__(self):
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY environment variable is required")
        
        self.openai_model = os.getenv("OPENAI_MODEL", "gpt-4")
        self.rate_limit = os.getenv("RATE_LIMIT_PER_MINUTE", "60")
        
        # Model pricing (per 1K tokens)
        self.pricing = {
            "gpt-4": 0.03,
            "gpt-4-turbo": 0.01,
            "gpt-3.5-turbo": 0.002
        }

settings = Settings()

# OpenAI client
openai_client = OpenAI(api_key=settings.openai_api_key)

# Function registry
function_registry: Dict[str, Dict[str, Any]] = {}
usage_stats: Dict[str, Dict[str, Any]] = {}

# Pydantic models
class FunctionCallRequest(BaseModel):
    message: str
    functions: Optional[List[str]] = None
    model: Optional[str] = None
    temperature: Optional[float] = None
    
    @validator('message')
    def validate_message(cls, v):
        if not v.strip():
            raise ValueError('Message cannot be empty')
        return v.strip()

class FunctionDefinition(BaseModel):
    name: str
    description: str
    parameters: Dict[str, Any]
    function_callable: Optional[str] = None
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('Function name cannot be empty')
        return v.strip()

class FunctionCallResponse(BaseModel):
    response: str
    function_calls: List[Dict[str, Any]]
    tokens_used: int
    cost: float
    model: str
    processing_time: float

class FunctionListResponse(BaseModel):
    functions: List[Dict[str, Any]]
    count: int

# Built-in functions
def get_current_time() -> str:
    """Get the current time in ISO format"""
    return datetime.utcnow().isoformat()

def calculate_math(expression: str) -> float:
    """Calculate a mathematical expression safely"""
    try:
        # Only allow basic mathematical operations
        allowed_chars = "0123456789+-*/.() "
        if not all(c in allowed_chars for c in expression):
            raise ValueError("Invalid characters in expression")
        
        # Use eval safely with limited scope
        result = eval(expression, {"__builtins__": {}}, {
            "abs": abs, "round": round, "min": min, "max": max,
            "pow": pow, "sqrt": math.sqrt, "sin": math.sin, "cos": math.cos,
            "tan": math.tan, "log": math.log, "pi": math.pi, "e": math.e
        })
        return float(result)
    except Exception as e:
        raise ValueError(f"Math calculation error: {e}")

def get_random_number(min_val: int = 1, max_val: int = 100) -> int:
    """Generate a random number between min and max values"""
    return random.randint(min_val, max_val)

def get_weather(location: str) -> Dict[str, Any]:
    """Get weather information for a location (mock implementation)"""
    # This is a mock implementation - in production, use a real weather API
    weather_conditions = ["sunny", "cloudy", "rainy", "snowy", "foggy"]
    return {
        "location": location,
        "temperature": random.randint(-10, 35),
        "condition": random.choice(weather_conditions),
        "humidity": random.randint(30, 90),
        "wind_speed": random.randint(0, 25),
        "timestamp": datetime.utcnow().isoformat()
    }

def format_text(text: str, style: str = "upper") -> str:
    """Format text with different styles"""
    styles = {
        "upper": str.upper,
        "lower": str.lower,
        "title": str.title,
        "capitalize": str.capitalize,
        "reverse": lambda x: x[::-1]
    }
    
    if style not in styles:
        raise ValueError(f"Unknown style: {style}. Available: {list(styles.keys())}")
    
    return styles[style](text)

def validate_email(email: str) -> Dict[str, Any]:
    """Validate email address format"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    is_valid = bool(re.match(pattern, email))
    
    return {
        "email": email,
        "is_valid": is_valid,
        "domain": email.split('@')[1] if '@' in email else None,
        "username": email.split('@')[0] if '@' in email else None
    }

# Function registration utilities
def register_function(name: str, func: Callable, description: str = None):
    """Register a function in the registry"""
    if description is None:
        description = func.__doc__ or "No description available"
    
    # Get function signature
    sig = inspect.signature(func)
    parameters = {
        "type": "object",
        "properties": {},
        "required": []
    }
    
    for param_name, param in sig.parameters.items():
        param_type = "string"  # Default type
        
        if param.annotation != inspect.Parameter.empty:
            if param.annotation == int:
                param_type = "integer"
            elif param.annotation == float:
                param_type = "number"
            elif param.annotation == bool:
                param_type = "boolean"
            elif param.annotation == dict:
                param_type = "object"
            elif param.annotation == list:
                param_type = "array"
        
        parameters["properties"][param_name] = {
            "type": param_type,
            "description": f"Parameter {param_name}"
        }
        
        if param.default == inspect.Parameter.empty:
            parameters["required"].append(param_name)
    
    function_registry[name] = {
        "name": name,
        "description": description,
        "parameters": parameters,
        "callable": func
    }

# Register built-in functions
register_function("get_current_time", get_current_time, "Get the current time in ISO format")
register_function("calculate_math", calculate_math, "Calculate mathematical expressions safely")
register_function("get_random_number", get_random_number, "Generate random numbers within range")
register_function("get_weather", get_weather, "Get weather information for a location")
register_function("format_text", format_text, "Format text with different styles")
register_function("validate_email", validate_email, "Validate email address format")

# Utility functions
def count_tokens(text: str) -> int:
    """Estimate token count for text"""
    return len(text.split()) * 1.3

def calculate_cost(tokens: int, model: str) -> float:
    """Calculate cost based on token usage"""
    rate = settings.pricing.get(model, 0.03)
    return (tokens / 1000) * rate

def execute_function(name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
    """Execute a registered function"""
    if name not in function_registry:
        return {"error": f"Function '{name}' not found"}
    
    try:
        func = function_registry[name]["callable"]
        result = func(**arguments)
        return {"result": result}
    except Exception as e:
        return {"error": str(e)}

def update_usage_stats(client_ip: str, tokens: int, cost: float):
    """Update usage statistics"""
    if client_ip not in usage_stats:
        usage_stats[client_ip] = {
            "total_requests": 0,
            "total_tokens": 0,
            "total_cost": 0.0,
            "function_calls": 0,
            "first_request": datetime.utcnow(),
            "last_request": datetime.utcnow()
        }
    
    stats = usage_stats[client_ip]
    stats["total_requests"] += 1
    stats["total_tokens"] += tokens
    stats["total_cost"] += cost
    stats["last_request"] = datetime.utcnow()

# Dependencies
def get_client_ip(request: Request) -> str:
    """Get client IP address"""
    return get_remote_address(request)

# Routes
@app.get("/", tags=["root"])
async def root():
    """API health check"""
    return {
        "message": "Function Calling API is running",
        "version": "1.0.0",
        "model": settings.openai_model,
        "available_functions": len(function_registry),
        "endpoints": {
            "call": "/functions/call",
            "list": "/functions/list",
            "register": "/functions/register"
        }
    }

@app.post("/functions/call", response_model=FunctionCallResponse, tags=["functions"])
@limiter.limit(f"{settings.rate_limit}/minute")
async def call_functions(
    request: Request,
    function_request: FunctionCallRequest,
    background_tasks: BackgroundTasks,
    client_ip: str = Depends(get_client_ip)
):
    """Execute function calls with AI"""
    start_time = time.time()
    
    model = function_request.model or settings.openai_model
    temperature = function_request.temperature or 0.7
    
    # Prepare functions for OpenAI
    available_functions = []
    if function_request.functions:
        # Use only specified functions
        for func_name in function_request.functions:
            if func_name in function_registry:
                func_def = function_registry[func_name]
                available_functions.append({
                    "type": "function",
                    "function": {
                        "name": func_def["name"],
                        "description": func_def["description"],
                        "parameters": func_def["parameters"]
                    }
                })
    else:
        # Use all available functions
        for func_def in function_registry.values():
            available_functions.append({
                "type": "function",
                "function": {
                    "name": func_def["name"],
                    "description": func_def["description"],
                    "parameters": func_def["parameters"]
                }
            })
    
    try:
        # Make API call
        messages = [
            {"role": "system", "content": "You are a helpful assistant with access to functions. Use them when appropriate."},
            {"role": "user", "content": function_request.message}
        ]
        
        response = openai_client.chat.completions.create(
            model=model,
            messages=messages,
            tools=available_functions,
            tool_choice="auto",
            temperature=temperature
        )
        
        # Process response
        message = response.choices[0].message
        function_calls = []
        
        # Execute function calls if any
        if message.tool_calls:
            for tool_call in message.tool_calls:
                function_name = tool_call.function.name
                function_args = json.loads(tool_call.function.arguments)
                
                # Execute function
                result = execute_function(function_name, function_args)
                
                function_calls.append({
                    "name": function_name,
                    "arguments": function_args,
                    "result": result.get("result"),
                    "error": result.get("error")
                })
                
                # Add function result to messages for follow-up
                messages.append({
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [tool_call]
                })
                messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result)
                })
            
            # Get final response with function results
            final_response = openai_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=temperature
            )
            
            final_message = final_response.choices[0].message.content
            total_tokens = response.usage.total_tokens + final_response.usage.total_tokens
        else:
            final_message = message.content
            total_tokens = response.usage.total_tokens
        
        # Calculate metrics
        cost = calculate_cost(total_tokens, model)
        processing_time = time.time() - start_time
        
        # Update usage stats
        background_tasks.add_task(
            update_usage_stats,
            client_ip,
            total_tokens,
            cost
        )
        
        # Update function call count
        if client_ip in usage_stats:
            usage_stats[client_ip]["function_calls"] += len(function_calls)
        
        return FunctionCallResponse(
            response=final_message,
            function_calls=function_calls,
            tokens_used=total_tokens,
            cost=cost,
            model=model,
            processing_time=processing_time
        )
        
    except Exception as e:
        logger.error(f"Function call error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/functions/list", response_model=FunctionListResponse, tags=["functions"])
async def list_functions():
    """List all available functions"""
    functions = []
    for func_def in function_registry.values():
        functions.append({
            "name": func_def["name"],
            "description": func_def["description"],
            "parameters": func_def["parameters"]
        })
    
    return FunctionListResponse(
        functions=functions,
        count=len(functions)
    )

@app.post("/functions/register", tags=["functions"])
async def register_custom_function(function_def: FunctionDefinition):
    """Register a new custom function (placeholder - requires implementation)"""
    # In a real implementation, this would need to handle:
    # - Code validation and sandboxing
    # - Dynamic function creation
    # - Security considerations
    
    return {
        "message": "Function registration not implemented in this example",
        "note": "This would require dynamic code execution and security measures"
    }

@app.get("/functions/{function_name}", tags=["functions"])
async def get_function_info(function_name: str):
    """Get detailed information about a specific function"""
    if function_name not in function_registry:
        raise HTTPException(status_code=404, detail="Function not found")
    
    func_def = function_registry[function_name]
    return {
        "name": func_def["name"],
        "description": func_def["description"],
        "parameters": func_def["parameters"],
        "usage_example": f"Ask the AI to use '{function_name}' in your message"
    }

@app.get("/stats", tags=["stats"])
async def get_stats(client_ip: str = Depends(get_client_ip)):
    """Get usage statistics"""
    if client_ip not in usage_stats:
        return {
            "total_requests": 0,
            "total_tokens": 0,
            "total_cost": 0.0,
            "function_calls": 0,
            "available_functions": len(function_registry)
        }
    
    stats = usage_stats[client_ip]
    return {
        "total_requests": stats["total_requests"],
        "total_tokens": stats["total_tokens"],
        "total_cost": stats["total_cost"],
        "function_calls": stats["function_calls"],
        "available_functions": len(function_registry),
        "first_request": stats["first_request"],
        "last_request": stats["last_request"]
    }

@app.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint"""
    try:
        # Test OpenAI connection
        test_response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": "test"}],
            max_tokens=1
        )
        
        return {
            "status": "healthy",
            "openai": "connected",
            "model": settings.openai_model,
            "available_functions": len(function_registry)
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "openai": "disconnected",
            "error": str(e)
        }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return {"error": exc.detail, "status_code": exc.status_code}

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unexpected error: {exc}")
    return {"error": "Internal server error", "status_code": 500}

# Middleware for logging
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.method} {request.url.path} - "
        f"Status: {response.status_code} - "
        f"Time: {process_time:.3f}s"
    )
    
    return response

# Run with: uvicorn example-function-calling-api:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")