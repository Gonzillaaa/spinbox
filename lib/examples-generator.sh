#!/bin/bash
# Examples Generator for Spinbox
# Generates working code examples for components

# Generate basic FastAPI example
function generate_fastapi_example() {
    local project_dir="$1"
    local fastapi_dir="$project_dir/fastapi"
    local app_dir="$fastapi_dir/app"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would generate FastAPI example"
        return 0
    fi
    
    print_info "Generating FastAPI example..."
    
    # Create directory structure
    mkdir -p "$app_dir"
    
    # Create main.py with basic example
    cat > "$app_dir/main.py" << 'EOF'
from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

app = FastAPI(title="FastAPI Example", version="1.0.0")

class Message(BaseModel):
    id: str
    content: str
    timestamp: datetime

class MessageCreate(BaseModel):
    content: str

# In-memory storage for demo
messages = []

@app.get("/")
def root():
    return {"message": "Hello World", "timestamp": datetime.now()}

@app.get("/health")
def health():
    return {"status": "healthy", "timestamp": datetime.now()}

@app.post("/messages", response_model=Message)
def create_message(message: MessageCreate):
    new_message = Message(
        id=str(len(messages) + 1),
        content=message.content,
        timestamp=datetime.now()
    )
    messages.append(new_message)
    return new_message

@app.get("/messages", response_model=List[Message])
def get_messages():
    return messages

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF
    
    # Create __init__.py
    cat > "$app_dir/__init__.py" << 'EOF'
"""FastAPI Application"""
EOF
    
    print_status "Generated FastAPI example in $app_dir"
}

# Generate basic Next.js example
function generate_nextjs_example() {
    local project_dir="$1"
    local nextjs_dir="$project_dir/frontend"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would generate Next.js example"
        return 0
    fi
    
    print_info "Generating Next.js example..."
    
    # Create directory structure
    mkdir -p "$nextjs_dir/pages"
    mkdir -p "$nextjs_dir/components"
    mkdir -p "$nextjs_dir/lib"
    
    # Create pages/index.tsx
    cat > "$nextjs_dir/pages/index.tsx" << 'EOF'
import React, { useState, useEffect } from 'react';
import Head from 'next/head';

interface Message {
  id: string;
  content: string;
  timestamp: string;
}

export default function Home() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

  const fetchMessages = async () => {
    try {
      const response = await fetch(`${apiUrl}/messages`);
      if (response.ok) {
        const data = await response.json();
        setMessages(data);
      }
    } catch (error) {
      console.error('Failed to fetch messages:', error);
    }
  };

  const createMessage = async () => {
    if (!newMessage.trim()) return;
    
    setLoading(true);
    try {
      const response = await fetch(`${apiUrl}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content: newMessage }),
      });
      
      if (response.ok) {
        setNewMessage('');
        await fetchMessages();
      }
    } catch (error) {
      console.error('Failed to create message:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMessages();
  }, []);

  return (
    <>
      <Head>
        <title>Next.js + FastAPI Example</title>
        <meta name="description" content="Example Next.js app with FastAPI backend" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>

      <main className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">Next.js + FastAPI Example</h1>
        
        <div className="mb-8">
          <div className="flex gap-2 mb-4">
            <input
              type="text"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Enter a message..."
              className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
              onKeyPress={(e) => e.key === 'Enter' && createMessage()}
            />
            <button
              onClick={createMessage}
              disabled={loading}
              className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:opacity-50"
            >
              {loading ? 'Adding...' : 'Add Message'}
            </button>
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="text-xl font-semibold">Messages</h2>
          {messages.length === 0 ? (
            <p className="text-gray-500">No messages yet. Add one above!</p>
          ) : (
            <div className="space-y-2">
              {messages.map((message) => (
                <div key={message.id} className="p-3 bg-gray-100 rounded-md">
                  <p className="font-medium">{message.content}</p>
                  <p className="text-sm text-gray-500">
                    {new Date(message.timestamp).toLocaleString()}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </>
  );
}
EOF
    
    # Create .env.local.example
    cat > "$nextjs_dir/.env.local.example" << 'EOF'
# Next.js Environment Variables
# Copy this file to .env.local and fill in your values

# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=Next.js Example
EOF
    
    print_status "Generated Next.js example in $nextjs_dir"
}

# Generate environment configuration
function generate_environment_example() {
    local project_dir="$1"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would generate environment configuration"
        return 0
    fi
    
    print_info "Generating environment configuration..."
    
    # Create .env.example
    cat > "$project_dir/.env.example" << 'EOF'
# Environment Configuration Template
# Copy this file to .env and fill in your actual values

# Application Settings
DEBUG=true
SECRET_KEY=your-secret-key-here
API_HOST=0.0.0.0
API_PORT=8000

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/database_name

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# External APIs
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here
EOF
    
    print_status "Generated environment configuration"
}

# Main function to generate examples for a component
function generate_component_examples() {
    local project_dir="$1"
    local component="$2"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        print_debug "Skipping example generation (--with-examples not specified)"
        return 0
    fi
    
    print_debug "Generating examples for component: $component"
    
    case "$component" in
        "fastapi")
            generate_fastapi_example "$project_dir"
            ;;
        "nextjs")
            generate_nextjs_example "$project_dir"
            ;;
        *)
            print_debug "No examples available for component: $component"
            ;;
    esac
}

# Generate examples for multiple components
function generate_examples_for_components() {
    local project_dir="$1"
    local components="$2"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        print_debug "Skipping example generation (--with-examples not specified)"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would generate examples for components: $components"
        return 0
    fi
    
    print_info "Processing examples for components: $components"
    
    # Generate environment configuration first
    generate_environment_example "$project_dir"
    
    # Process each component
    for component in $components; do
        # Remove leading -- from component name
        local clean_component="${component#--}"
        generate_component_examples "$project_dir" "$clean_component"
    done
}

# Export functions for use in other scripts
export -f generate_component_examples
export -f generate_examples_for_components
export -f generate_environment_example