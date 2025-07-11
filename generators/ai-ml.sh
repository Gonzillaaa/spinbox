#!/bin/bash
# AI/ML component generator for Spinbox
# Creates AI/ML environment with LLM integration, vector processing, and agent workflows

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"

# Generate AI/ML framework component
function generate_ai_ml_component() {
    local project_dir="$1"
    local aiml_dir="$project_dir/ai-ml"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate AI/ML framework component"
        return 0
    fi
    
    print_status "Creating AI/ML framework component..."
    
    # Ensure AI/ML directory structure exists
    safe_create_dir "$aiml_dir"
    safe_create_dir "$aiml_dir/notebooks"
    safe_create_dir "$aiml_dir/agents"
    safe_create_dir "$aiml_dir/prompts"
    safe_create_dir "$aiml_dir/models"
    safe_create_dir "$aiml_dir/vectorstores"
    safe_create_dir "$aiml_dir/tools"
    safe_create_dir "$aiml_dir/workflows"
    safe_create_dir "$aiml_dir/data"
    safe_create_dir "$aiml_dir/scripts"
    safe_create_dir "$aiml_dir/tests"
    
    # Generate AI/ML files
    generate_aiml_dockerfiles "$aiml_dir"
    generate_aiml_requirements "$aiml_dir"
    generate_aiml_notebooks "$aiml_dir"
    generate_aiml_agents "$aiml_dir"
    generate_aiml_tools "$aiml_dir"
    generate_aiml_workflows "$aiml_dir"
    generate_aiml_config "$aiml_dir"
    generate_aiml_tests "$aiml_dir"
    generate_aiml_env_files "$aiml_dir"
    
    print_status "AI/ML framework component created successfully"
}

# Generate Docker configuration for AI/ML
function generate_aiml_dockerfiles() {
    local aiml_dir="$1"
    local python_version=$(get_effective_python_version)
    
    # Development Dockerfile with AI/ML tools
    cat > "$aiml_dir/Dockerfile.dev" << EOF
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
    && sed -i 's/plugins=(git)/plugins=(git docker python pip)/g' ~/.zshrc \\
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Set up virtual environment path
ENV PATH="/workspace/venv/bin:\$PATH"

# Add AI/ML aliases
RUN echo '# AI/ML aliases' >> ~/.zshrc \\
    && echo 'alias jlab="jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root"' >> ~/.zshrc \\
    && echo 'alias pytest="python -m pytest"' >> ~/.zshrc \\
    && echo 'alias uvinstall="uv pip install -r requirements.txt"' >> ~/.zshrc \\
    && echo 'alias agent="python scripts/run_agent.py"' >> ~/.zshrc \\
    && echo 'alias chat="python scripts/chat_interface.py"' >> ~/.zshrc \\
    && echo 'alias embed="python scripts/create_embeddings.py"' >> ~/.zshrc

EXPOSE 8888

# Activate virtual environment on shell start
RUN echo 'if [[ -f /workspace/venv/bin/activate ]]; then source /workspace/venv/bin/activate; fi' >> ~/.zshrc

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
EOF

    # Production Dockerfile
    cat > "$aiml_dir/Dockerfile" << EOF
FROM python:${python_version}-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    build-essential \\
    && rm -rf /var/lib/apt/lists/*

# Install UV for dependency management
RUN pip install --no-cache-dir uv

# Create and activate virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:\$PATH"

# Copy and install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

# Copy project files
COPY . .

# Run Jupyter Lab by default
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
EOF

    # Docker ignore file
    cat > "$aiml_dir/.dockerignore" << 'EOF'
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
vectorstores/
models/
data/
*.log
.ipynb_checkpoints/
EOF

    print_debug "Generated AI/ML Docker configuration"
}

# Generate requirements.txt with AI/ML dependencies
function generate_aiml_requirements() {
    local aiml_dir="$1"
    
    cat > "$aiml_dir/requirements.txt" << 'EOF'
# LLM and AI frameworks
openai>=1.0.0
anthropic>=0.7.0
langchain>=0.1.0
langchain-community>=0.0.1
langchain-openai>=0.0.1
llama-index>=0.9.0

# Vector databases and embeddings
chromadb>=0.4.0
sentence-transformers>=2.2.0
faiss-cpu>=1.7.0
tiktoken>=0.5.0

# Agent frameworks
autogen>=0.2.0
crewai>=0.1.0

# LLM utilities
guidance>=0.1.0
transformers>=4.35.0
# torch>=2.0.0  # Optional: Heavy dependency, uncomment if needed for model training

# Data processing
pandas>=2.1.0
numpy>=1.24.0

# Web scraping and content processing
beautifulsoup4>=4.12.0
requests>=2.31.0
scrapy>=2.11.0
selenium>=4.15.0

# Jupyter and notebook tools
jupyter>=1.0.0
jupyterlab>=4.0.0
ipywidgets>=8.0.0

# Development tools
uv>=0.1.0
pytest>=7.4.0
black>=23.0.0
python-dotenv>=1.0.0

# Utilities
tqdm>=4.66.0
python-dateutil>=2.8.0
pydantic>=2.4.0
fastapi>=0.103.0
uvicorn>=0.23.0

# Optional heavy dependencies (uncomment if needed):
# torch>=2.0.0  # PyTorch - Heavy dependency for model training/inference
# tensorflow>=2.13.0  # TensorFlow - Alternative to PyTorch
EOF

    # Add optional dependencies based on selected components
    if [[ "${USE_POSTGRESQL:-false}" == "true" ]]; then
        cat >> "$aiml_dir/requirements.txt" << 'EOF'

# PostgreSQL dependencies
psycopg2-binary>=2.9.7
sqlalchemy>=2.0.0
EOF
    fi
    
    if [[ "${USE_MONGODB:-false}" == "true" ]]; then
        cat >> "$aiml_dir/requirements.txt" << 'EOF'

# MongoDB dependencies
pymongo>=4.5.0
motor>=3.3.0
EOF
    fi

    print_debug "Generated AI/ML requirements.txt"
}

# Generate Jupyter notebooks for AI/ML workflows
function generate_aiml_notebooks() {
    local aiml_dir="$1"
    local notebooks_dir="$aiml_dir/notebooks"
    
    # LLM exploration notebook
    cat > "$notebooks_dir/01_llm_exploration.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# LLM Exploration and Testing\n",
    "\n",
    "This notebook explores different LLM providers and their capabilities."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "from dotenv import load_dotenv\n",
    "import openai\n",
    "from anthropic import Anthropic\n",
    "from langchain.chat_models import ChatOpenAI\n",
    "from langchain.schema import HumanMessage, AIMessage\n",
    "\n",
    "# Load environment variables\n",
    "load_dotenv()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# OpenAI client setup\n",
    "openai_client = openai.OpenAI(\n",
    "    api_key=os.getenv('OPENAI_API_KEY')\n",
    ")\n",
    "\n",
    "# Anthropic client setup\n",
    "anthropic_client = Anthropic(\n",
    "    api_key=os.getenv('ANTHROPIC_API_KEY')\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Test OpenAI API\n",
    "def test_openai_chat(message: str):\n",
    "    response = openai_client.chat.completions.create(\n",
    "        model=\"gpt-4\",\n",
    "        messages=[\n",
    "            {\"role\": \"user\", \"content\": message}\n",
    "        ],\n",
    "        max_tokens=150\n",
    "    )\n",
    "    return response.choices[0].message.content\n",
    "\n",
    "# Test message\n",
    "test_message = \"Explain artificial intelligence in simple terms.\"\n",
    "# openai_response = test_openai_chat(test_message)\n",
    "# print(f\"OpenAI Response: {openai_response}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Test Anthropic API\n",
    "def test_anthropic_chat(message: str):\n",
    "    response = anthropic_client.messages.create(\n",
    "        model=\"claude-3-sonnet-20240229\",\n",
    "        max_tokens=150,\n",
    "        messages=[\n",
    "            {\"role\": \"user\", \"content\": message}\n",
    "        ]\n",
    "    )\n",
    "    return response.content[0].text\n",
    "\n",
    "# anthropic_response = test_anthropic_chat(test_message)\n",
    "# print(f\"Anthropic Response: {anthropic_response}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# LangChain integration\n",
    "def test_langchain_chat(message: str):\n",
    "    llm = ChatOpenAI(temperature=0.7)\n",
    "    messages = [HumanMessage(content=message)]\n",
    "    response = llm(messages)\n",
    "    return response.content\n",
    "\n",
    "# langchain_response = test_langchain_chat(test_message)\n",
    "# print(f\"LangChain Response: {langchain_response}\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Vector embeddings notebook
    cat > "$notebooks_dir/02_vector_embeddings.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Vector Embeddings and Similarity Search\n",
    "\n",
    "This notebook demonstrates vector embeddings and similarity search capabilities."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "from dotenv import load_dotenv\n",
    "import chromadb\n",
    "from sentence_transformers import SentenceTransformer\n",
    "import numpy as np\n",
    "from pathlib import Path\n",
    "\n",
    "# Load environment variables\n",
    "load_dotenv()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Initialize embedding model\n",
    "embedding_model = SentenceTransformer('all-MiniLM-L6-v2')\n",
    "\n",
    "# Initialize Chroma client\n",
    "chroma_client = chromadb.PersistentClient(path=\"../vectorstores/chroma\")\n",
    "collection = chroma_client.get_or_create_collection(name=\"documents\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Sample documents for testing\n",
    "sample_documents = [\n",
    "    \"Artificial intelligence is transforming how we work and live.\",\n",
    "    \"Machine learning algorithms can identify patterns in large datasets.\",\n",
    "    \"Natural language processing enables computers to understand human language.\",\n",
    "    \"Deep learning uses neural networks to solve complex problems.\",\n",
    "    \"Computer vision allows machines to interpret and analyze visual information.\"\n",
    "]\n",
    "\n",
    "# Generate embeddings\n",
    "embeddings = embedding_model.encode(sample_documents)\n",
    "print(f\"Generated embeddings shape: {embeddings.shape}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Add documents to vector store\n",
    "collection.add(\n",
    "    documents=sample_documents,\n",
    "    embeddings=embeddings.tolist(),\n",
    "    ids=[f\"doc_{i}\" for i in range(len(sample_documents))],\n",
    "    metadatas=[{\"source\": \"sample\", \"index\": i} for i in range(len(sample_documents))]\n",
    ")\n",
    "\n",
    "print(f\"Added {len(sample_documents)} documents to vector store\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Query the vector store\n",
    "query = \"How does AI help with data analysis?\"\n",
    "query_embedding = embedding_model.encode([query])\n",
    "\n",
    "results = collection.query(\n",
    "    query_embeddings=query_embedding.tolist(),\n",
    "    n_results=3\n",
    ")\n",
    "\n",
    "print(f\"Query: {query}\")\n",
    "print(\"\\nTop 3 similar documents:\")\n",
    "for i, doc in enumerate(results['documents'][0]):\n",
    "    print(f\"{i+1}. {doc}\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Agent workflow notebook
    cat > "$notebooks_dir/03_agent_workflows.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Agent Workflows and Automation\n",
    "\n",
    "This notebook demonstrates agent-based workflows and automation patterns."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "from dotenv import load_dotenv\n",
    "from langchain.agents import Tool, AgentExecutor, ZeroShotAgent\n",
    "from langchain.llms import OpenAI\n",
    "from langchain.utilities import GoogleSearchAPIWrapper\n",
    "from langchain.memory import ConversationBufferMemory\n",
    "from langchain.chains import LLMChain\n",
    "\n",
    "# Load environment variables\n",
    "load_dotenv()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Define tools for the agent\n",
    "def calculate_tool(expression: str) -> str:\n",
    "    \"\"\"Calculate mathematical expressions safely.\"\"\"\n",
    "    try:\n",
    "        # Simple eval for demonstration - use ast.literal_eval for safety\n",
    "        result = eval(expression)\n",
    "        return str(result)\n",
    "    except Exception as e:\n",
    "        return f\"Error: {str(e)}\"\n",
    "\n",
    "def text_analysis_tool(text: str) -> str:\n",
    "    \"\"\"Analyze text and provide statistics.\"\"\"\n",
    "    words = text.split()\n",
    "    return f\"Word count: {len(words)}, Character count: {len(text)}\"\n",
    "\n",
    "# Create tools\n",
    "tools = [\n",
    "    Tool(\n",
    "        name=\"Calculator\",\n",
    "        func=calculate_tool,\n",
    "        description=\"Useful for mathematical calculations\"\n",
    "    ),\n",
    "    Tool(\n",
    "        name=\"Text Analyzer\",\n",
    "        func=text_analysis_tool,\n",
    "        description=\"Analyzes text and provides statistics\"\n",
    "    )\n",
    "]"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create an agent\n",
    "llm = OpenAI(temperature=0)\n",
    "memory = ConversationBufferMemory(memory_key=\"chat_history\")\n",
    "\n",
    "prefix = \"\"\"You are a helpful assistant that can use tools to help users.\n",
    "You have access to the following tools:\"\"\"\n",
    "\n",
    "suffix = \"\"\"Begin!\n",
    "\n",
    "{chat_history}\n",
    "Question: {input}\n",
    "{agent_scratchpad}\"\"\"\n",
    "\n",
    "prompt = ZeroShotAgent.create_prompt(\n",
    "    tools,\n",
    "    prefix=prefix,\n",
    "    suffix=suffix,\n",
    "    input_variables=[\"input\", \"chat_history\", \"agent_scratchpad\"]\n",
    ")\n",
    "\n",
    "llm_chain = LLMChain(llm=llm, prompt=prompt)\n",
    "agent = ZeroShotAgent(llm_chain=llm_chain, tools=tools, verbose=True)\n",
    "agent_executor = AgentExecutor.from_agent_and_tools(\n",
    "    agent=agent,\n",
    "    tools=tools,\n",
    "    verbose=True,\n",
    "    memory=memory\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Test the agent\n",
    "# result = agent_executor.run(\"What is 25 * 4 + 10?\")\n",
    "# print(f\"Agent result: {result}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Test text analysis\n",
    "# result = agent_executor.run(\"Analyze this text: 'Artificial intelligence is revolutionizing the way we work and live.'\")\n",
    "# print(f\"Agent result: {result}\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    print_debug "Generated AI/ML notebooks"
}

# Generate agent implementations
function generate_aiml_agents() {
    local aiml_dir="$1"
    local agents_dir="$aiml_dir/agents"
    
    # Base agent class
    cat > "$agents_dir/base_agent.py" << 'EOF'
"""
Base agent class for AI/ML workflows.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

class BaseAgent(ABC):
    """Base class for all agents."""
    
    def __init__(self, name: str, model_name: str = "gpt-3.5-turbo"):
        self.name = name
        self.model_name = model_name
        self.conversation_history = []
        self.tools = []
    
    @abstractmethod
    def process_message(self, message: str) -> str:
        """Process a message and return a response."""
        pass
    
    def add_tool(self, tool: Any) -> None:
        """Add a tool to the agent."""
        self.tools.append(tool)
        logger.info(f"Added tool to {self.name}: {tool}")
    
    def get_conversation_history(self) -> List[Dict[str, str]]:
        """Get the conversation history."""
        return self.conversation_history
    
    def clear_conversation_history(self) -> None:
        """Clear the conversation history."""
        self.conversation_history = []
        logger.info(f"Cleared conversation history for {self.name}")
EOF

    # Research agent
    cat > "$agents_dir/research_agent.py" << 'EOF'
"""
Research agent for information gathering and analysis.
"""

import os
from typing import List, Dict, Any
from langchain.agents import Tool, AgentExecutor, ZeroShotAgent
from langchain.llms import OpenAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import LLMChain
from langchain.utilities import GoogleSearchAPIWrapper
from .base_agent import BaseAgent

class ResearchAgent(BaseAgent):
    """Agent specialized in research and information gathering."""
    
    def __init__(self, name: str = "Research Agent"):
        super().__init__(name)
        self.llm = OpenAI(temperature=0.3)
        self.memory = ConversationBufferMemory(memory_key="chat_history")
        self.setup_tools()
        self.setup_agent()
    
    def setup_tools(self) -> None:
        """Set up research tools."""
        tools = []
        
        # Search tool (requires Google API key)
        if os.getenv("GOOGLE_API_KEY") and os.getenv("GOOGLE_CSE_ID"):
            search = GoogleSearchAPIWrapper()
            tools.append(Tool(
                name="Search",
                func=search.run,
                description="Useful for searching the web for current information"
            ))
        
        # Document analysis tool
        def analyze_document(text: str) -> str:
            """Analyze document content."""
            words = text.split()
            sentences = text.split('.')
            return f"Document analysis: {len(words)} words, {len(sentences)} sentences"
        
        tools.append(Tool(
            name="Document Analyzer",
            func=analyze_document,
            description="Analyzes documents and provides statistics"
        ))
        
        self.tools = tools
    
    def setup_agent(self) -> None:
        """Set up the research agent."""
        prefix = """You are a research assistant that helps gather and analyze information.
        You have access to the following tools:"""
        
        suffix = """Begin!
        
        {chat_history}
        Question: {input}
        {agent_scratchpad}"""
        
        prompt = ZeroShotAgent.create_prompt(
            self.tools,
            prefix=prefix,
            suffix=suffix,
            input_variables=["input", "chat_history", "agent_scratchpad"]
        )
        
        llm_chain = LLMChain(llm=self.llm, prompt=prompt)
        agent = ZeroShotAgent(llm_chain=llm_chain, tools=self.tools, verbose=True)
        
        self.agent_executor = AgentExecutor.from_agent_and_tools(
            agent=agent,
            tools=self.tools,
            verbose=True,
            memory=self.memory
        )
    
    def process_message(self, message: str) -> str:
        """Process a research request."""
        try:
            result = self.agent_executor.run(message)
            self.conversation_history.append({
                "role": "user",
                "content": message
            })
            self.conversation_history.append({
                "role": "assistant",
                "content": result
            })
            return result
        except Exception as e:
            error_msg = f"Error processing research request: {str(e)}"
            return error_msg
EOF

    # Writing agent
    cat > "$agents_dir/writing_agent.py" << 'EOF'
"""
Writing agent for content creation and editing.
"""

import os
from typing import List, Dict, Any
from langchain.llms import OpenAI
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain
from .base_agent import BaseAgent

class WritingAgent(BaseAgent):
    """Agent specialized in content writing and editing."""
    
    def __init__(self, name: str = "Writing Agent"):
        super().__init__(name)
        self.llm = OpenAI(temperature=0.7)
        self.setup_chains()
    
    def setup_chains(self) -> None:
        """Set up writing chains."""
        # Content writing chain
        self.writing_prompt = PromptTemplate(
            input_variables=["topic", "style", "length"],
            template="""Write a {style} piece about {topic}.
            The content should be approximately {length} words.
            Make it engaging and informative.
            
            Topic: {topic}
            Style: {style}
            Length: {length}
            
            Content:"""
        )
        
        self.writing_chain = LLMChain(
            llm=self.llm,
            prompt=self.writing_prompt
        )
        
        # Editing chain
        self.editing_prompt = PromptTemplate(
            input_variables=["content", "instruction"],
            template="""Edit the following content based on the instruction:
            
            Instruction: {instruction}
            
            Original Content:
            {content}
            
            Edited Content:"""
        )
        
        self.editing_chain = LLMChain(
            llm=self.llm,
            prompt=self.editing_prompt
        )
    
    def process_message(self, message: str) -> str:
        """Process a writing request."""
        try:
            if "write" in message.lower():
                return self.handle_writing_request(message)
            elif "edit" in message.lower():
                return self.handle_editing_request(message)
            else:
                return self.handle_general_request(message)
        except Exception as e:
            return f"Error processing writing request: {str(e)}"
    
    def handle_writing_request(self, message: str) -> str:
        """Handle writing requests."""
        # Simple parsing - could be improved with NLP
        topic = "general topic"
        style = "informative"
        length = "200"
        
        result = self.writing_chain.run(
            topic=topic,
            style=style,
            length=length
        )
        
        return result
    
    def handle_editing_request(self, message: str) -> str:
        """Handle editing requests."""
        # This is a simplified example
        content = "Sample content to edit"
        instruction = "Improve clarity and grammar"
        
        result = self.editing_chain.run(
            content=content,
            instruction=instruction
        )
        
        return result
    
    def handle_general_request(self, message: str) -> str:
        """Handle general writing-related requests."""
        return f"I can help with writing and editing tasks. How can I assist you with content creation?"
EOF

    print_debug "Generated AI/ML agents"
}

# Generate tools and utilities
function generate_aiml_tools() {
    local aiml_dir="$1"
    local tools_dir="$aiml_dir/tools"
    
    # LLM client utility
    cat > "$tools_dir/llm_client.py" << 'EOF'
"""
LLM client utilities for various providers.
"""

import os
from typing import Dict, Any, Optional
from dotenv import load_dotenv
import openai
from anthropic import Anthropic

load_dotenv()

class LLMClient:
    """Unified client for multiple LLM providers."""
    
    def __init__(self):
        self.openai_client = openai.OpenAI(
            api_key=os.getenv('OPENAI_API_KEY')
        ) if os.getenv('OPENAI_API_KEY') else None
        
        self.anthropic_client = Anthropic(
            api_key=os.getenv('ANTHROPIC_API_KEY')
        ) if os.getenv('ANTHROPIC_API_KEY') else None
    
    def chat_openai(self, message: str, model: str = "gpt-3.5-turbo", **kwargs) -> str:
        """Chat with OpenAI models."""
        if not self.openai_client:
            raise ValueError("OpenAI API key not configured")
        
        response = self.openai_client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": message}],
            **kwargs
        )
        
        return response.choices[0].message.content
    
    def chat_anthropic(self, message: str, model: str = "claude-3-sonnet-20240229", **kwargs) -> str:
        """Chat with Anthropic models."""
        if not self.anthropic_client:
            raise ValueError("Anthropic API key not configured")
        
        response = self.anthropic_client.messages.create(
            model=model,
            max_tokens=kwargs.get('max_tokens', 1000),
            messages=[{"role": "user", "content": message}]
        )
        
        return response.content[0].text
    
    def generate_embeddings(self, text: str, model: str = "text-embedding-ada-002") -> list:
        """Generate embeddings using OpenAI."""
        if not self.openai_client:
            raise ValueError("OpenAI API key not configured")
        
        response = self.openai_client.embeddings.create(
            model=model,
            input=text
        )
        
        return response.data[0].embedding
EOF

    # Vector store utility
    cat > "$tools_dir/vector_store.py" << 'EOF'
"""
Vector store utilities for embeddings and similarity search.
"""

import os
from typing import List, Dict, Any, Optional
from pathlib import Path
import chromadb
from sentence_transformers import SentenceTransformer
import numpy as np

class VectorStore:
    """Unified vector store interface."""
    
    def __init__(self, collection_name: str = "documents", persist_directory: str = "vectorstores"):
        self.collection_name = collection_name
        self.persist_directory = Path(persist_directory)
        self.persist_directory.mkdir(parents=True, exist_ok=True)
        
        # Initialize embedding model
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Initialize Chroma client
        self.client = chromadb.PersistentClient(path=str(self.persist_directory / "chroma"))
        self.collection = self.client.get_or_create_collection(name=collection_name)
    
    def add_documents(self, documents: List[str], metadata: Optional[List[Dict]] = None) -> None:
        """Add documents to the vector store."""
        embeddings = self.embedding_model.encode(documents)
        
        ids = [f"doc_{i}" for i in range(len(documents))]
        metadata = metadata or [{"source": "unknown"} for _ in documents]
        
        self.collection.add(
            documents=documents,
            embeddings=embeddings.tolist(),
            ids=ids,
            metadatas=metadata
        )
    
    def search(self, query: str, n_results: int = 5) -> Dict[str, Any]:
        """Search for similar documents."""
        query_embedding = self.embedding_model.encode([query])
        
        results = self.collection.query(
            query_embeddings=query_embedding.tolist(),
            n_results=n_results
        )
        
        return {
            "documents": results["documents"][0],
            "distances": results["distances"][0],
            "metadata": results["metadatas"][0]
        }
    
    def delete_collection(self) -> None:
        """Delete the collection."""
        self.client.delete_collection(name=self.collection_name)
    
    def get_collection_info(self) -> Dict[str, Any]:
        """Get information about the collection."""
        count = self.collection.count()
        return {
            "name": self.collection_name,
            "count": count,
            "persist_directory": str(self.persist_directory)
        }
EOF

    # Prompt template utility
    cat > "$tools_dir/prompt_templates.py" << 'EOF'
"""
Prompt templates for common AI/ML tasks.
"""

from typing import Dict, Any
from string import Template

class PromptTemplates:
    """Collection of prompt templates for various tasks."""
    
    CHAT_TEMPLATE = Template("""
    You are a helpful AI assistant. Please respond to the user's question.
    
    User: $user_message
    Assistant:
    """)
    
    RESEARCH_TEMPLATE = Template("""
    You are a research assistant. Please research the following topic and provide a comprehensive summary.
    
    Topic: $topic
    Focus areas: $focus_areas
    Required length: $length
    
    Please provide:
    1. Key findings
    2. Important sources
    3. Summary conclusion
    
    Research:
    """)
    
    WRITING_TEMPLATE = Template("""
    You are a professional writer. Please write content on the following topic.
    
    Topic: $topic
    Style: $style
    Target audience: $audience
    Length: $length words
    
    Content:
    """)
    
    CODE_REVIEW_TEMPLATE = Template("""
    You are a senior software engineer. Please review the following code and provide feedback.
    
    Code:
    $code
    
    Please provide:
    1. Code quality assessment
    2. Potential issues or bugs
    3. Suggestions for improvement
    4. Best practices recommendations
    
    Review:
    """)
    
    SUMMARIZATION_TEMPLATE = Template("""
    Please summarize the following text in approximately $length words.
    
    Original text:
    $text
    
    Summary:
    """)
    
    @classmethod
    def get_template(cls, template_name: str) -> Template:
        """Get a specific template by name."""
        templates = {
            "chat": cls.CHAT_TEMPLATE,
            "research": cls.RESEARCH_TEMPLATE,
            "writing": cls.WRITING_TEMPLATE,
            "code_review": cls.CODE_REVIEW_TEMPLATE,
            "summarization": cls.SUMMARIZATION_TEMPLATE
        }
        
        return templates.get(template_name, cls.CHAT_TEMPLATE)
    
    @classmethod
    def render_template(cls, template_name: str, **kwargs) -> str:
        """Render a template with provided variables."""
        template = cls.get_template(template_name)
        return template.substitute(**kwargs)
EOF

    print_debug "Generated AI/ML tools"
}

# Generate workflow scripts
function generate_aiml_workflows() {
    local aiml_dir="$1"
    local workflows_dir="$aiml_dir/workflows"
    
    # Document processing workflow
    cat > "$workflows_dir/document_processing.py" << 'EOF'
#!/usr/bin/env python3
"""
Document processing workflow for AI/ML projects.
"""

import os
from pathlib import Path
from typing import List, Dict, Any
import logging
from ..tools.vector_store import VectorStore
from ..tools.llm_client import LLMClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DocumentProcessor:
    """Workflow for processing documents with AI/ML."""
    
    def __init__(self, vector_store: VectorStore, llm_client: LLMClient):
        self.vector_store = vector_store
        self.llm_client = llm_client
    
    def process_directory(self, directory: Path) -> Dict[str, Any]:
        """Process all documents in a directory."""
        logger.info(f"Processing documents in {directory}")
        
        documents = []
        metadata = []
        
        for file_path in directory.glob("*.txt"):
            content = file_path.read_text()
            documents.append(content)
            metadata.append({
                "source": str(file_path),
                "filename": file_path.name
            })
        
        # Add to vector store
        self.vector_store.add_documents(documents, metadata)
        
        # Generate summaries
        summaries = []
        for doc in documents:
            summary = self.llm_client.chat_openai(
                f"Summarize this document in 2-3 sentences: {doc[:1000]}..."
            )
            summaries.append(summary)
        
        return {
            "processed_count": len(documents),
            "summaries": summaries,
            "vector_store_info": self.vector_store.get_collection_info()
        }
    
    def search_documents(self, query: str, n_results: int = 5) -> Dict[str, Any]:
        """Search processed documents."""
        results = self.vector_store.search(query, n_results)
        
        # Generate enhanced response using LLM
        context = "\n".join(results["documents"])
        enhanced_response = self.llm_client.chat_openai(
            f"Based on the following context, answer the question: {query}\n\nContext:\n{context}"
        )
        
        return {
            "query": query,
            "similar_documents": results["documents"],
            "enhanced_response": enhanced_response
        }

def main():
    """Main document processing workflow."""
    vector_store = VectorStore("documents")
    llm_client = LLMClient()
    processor = DocumentProcessor(vector_store, llm_client)
    
    # Process documents
    data_dir = Path("data")
    if data_dir.exists():
        result = processor.process_directory(data_dir)
        print(f"Processed {result['processed_count']} documents")
    
    # Example search
    search_result = processor.search_documents("What are the main topics?")
    print(f"Search result: {search_result['enhanced_response']}")

if __name__ == "__main__":
    main()
EOF

    # Chat workflow
    cat > "$workflows_dir/chat_workflow.py" << 'EOF'
#!/usr/bin/env python3
"""
Interactive chat workflow with context management.
"""

import os
from typing import List, Dict, Any
from ..agents.research_agent import ResearchAgent
from ..agents.writing_agent import WritingAgent
from ..tools.llm_client import LLMClient

class ChatWorkflow:
    """Interactive chat workflow with multiple agents."""
    
    def __init__(self):
        self.llm_client = LLMClient()
        self.research_agent = ResearchAgent()
        self.writing_agent = WritingAgent()
        self.current_agent = None
        self.conversation_history = []
    
    def process_message(self, message: str) -> str:
        """Process a message and route to appropriate agent."""
        # Simple routing logic
        if "research" in message.lower() or "search" in message.lower():
            self.current_agent = self.research_agent
            response = self.research_agent.process_message(message)
        elif "write" in message.lower() or "edit" in message.lower():
            self.current_agent = self.writing_agent
            response = self.writing_agent.process_message(message)
        else:
            # Default to general chat
            response = self.llm_client.chat_openai(message)
        
        # Store in conversation history
        self.conversation_history.append({
            "role": "user",
            "content": message
        })
        self.conversation_history.append({
            "role": "assistant",
            "content": response
        })
        
        return response
    
    def get_conversation_summary(self) -> str:
        """Get a summary of the conversation."""
        if not self.conversation_history:
            return "No conversation history"
        
        history_text = "\n".join([
            f"{msg['role']}: {msg['content']}"
            for msg in self.conversation_history
        ])
        
        summary = self.llm_client.chat_openai(
            f"Summarize this conversation in 2-3 sentences:\n{history_text}"
        )
        
        return summary
    
    def export_conversation(self, filename: str) -> None:
        """Export conversation to a file."""
        with open(filename, 'w') as f:
            for msg in self.conversation_history:
                f.write(f"{msg['role']}: {msg['content']}\n\n")

def main():
    """Main chat workflow."""
    workflow = ChatWorkflow()
    
    print("AI/ML Chat Workflow")
    print("Type 'quit' to exit, 'summary' for conversation summary")
    print("-" * 50)
    
    while True:
        user_input = input("\nYou: ").strip()
        
        if user_input.lower() == 'quit':
            break
        elif user_input.lower() == 'summary':
            summary = workflow.get_conversation_summary()
            print(f"\nConversation Summary: {summary}")
        else:
            response = workflow.process_message(user_input)
            print(f"\nAssistant: {response}")

if __name__ == "__main__":
    main()
EOF

    print_debug "Generated AI/ML workflows"
}

# Generate configuration files
function generate_aiml_config() {
    local aiml_dir="$1"
    
    # AI/ML configuration
    cat > "$aiml_dir/config.py" << 'EOF'
"""
AI/ML project configuration settings.
"""

import os
from pathlib import Path
from typing import Dict, Any

# Project paths
PROJECT_ROOT = Path(__file__).parent
DATA_DIR = PROJECT_ROOT / "data"
MODELS_DIR = PROJECT_ROOT / "models"
VECTORSTORES_DIR = PROJECT_ROOT / "vectorstores"
PROMPTS_DIR = PROJECT_ROOT / "prompts"
AGENTS_DIR = PROJECT_ROOT / "agents"
WORKFLOWS_DIR = PROJECT_ROOT / "workflows"
NOTEBOOKS_DIR = PROJECT_ROOT / "notebooks"

# Create directories if they don't exist
for dir_path in [DATA_DIR, MODELS_DIR, VECTORSTORES_DIR, PROMPTS_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)

# LLM Settings
DEFAULT_OPENAI_MODEL = "gpt-3.5-turbo"
DEFAULT_ANTHROPIC_MODEL = "claude-3-sonnet-20240229"
DEFAULT_EMBEDDING_MODEL = "text-embedding-ada-002"

# Vector Store Settings
DEFAULT_VECTOR_STORE = "chroma"
DEFAULT_COLLECTION_NAME = "documents"
SIMILARITY_THRESHOLD = 0.7
MAX_SEARCH_RESULTS = 10

# Agent Settings
AGENT_TIMEOUT = 30  # seconds
MAX_ITERATIONS = 5
VERBOSE_AGENTS = True

# Workflow Settings
MAX_CONTEXT_LENGTH = 4000
BATCH_SIZE = 10
PARALLEL_PROCESSING = True

# Model Parameters
TEMPERATURE = 0.7
MAX_TOKENS = 1000
TOP_P = 0.9

# Prompt Templates Directory
PROMPT_TEMPLATES_DIR = PROMPTS_DIR / "templates"

# Environment Variables
REQUIRED_ENV_VARS = [
    "OPENAI_API_KEY",
    "ANTHROPIC_API_KEY"
]

OPTIONAL_ENV_VARS = [
    "GOOGLE_API_KEY",
    "GOOGLE_CSE_ID",
    "PINECONE_API_KEY",
    "PINECONE_ENVIRONMENT"
]

def get_config() -> Dict[str, Any]:
    """Get current configuration."""
    return {
        "project_root": PROJECT_ROOT,
        "data_dir": DATA_DIR,
        "models_dir": MODELS_DIR,
        "vectorstores_dir": VECTORSTORES_DIR,
        "default_openai_model": DEFAULT_OPENAI_MODEL,
        "default_anthropic_model": DEFAULT_ANTHROPIC_MODEL,
        "temperature": TEMPERATURE,
        "max_tokens": MAX_TOKENS
    }

def check_environment() -> Dict[str, bool]:
    """Check if required environment variables are set."""
    env_status = {}
    
    for var in REQUIRED_ENV_VARS:
        env_status[var] = os.getenv(var) is not None
    
    for var in OPTIONAL_ENV_VARS:
        env_status[f"{var} (optional)"] = os.getenv(var) is not None
    
    return env_status
EOF

    print_debug "Generated AI/ML configuration"
}

# Generate test files
function generate_aiml_tests() {
    local aiml_dir="$1"
    local tests_dir="$aiml_dir/tests"
    
    cat > "$tests_dir/__init__.py" << 'EOF'
"""AI/ML tests."""
EOF

    cat > "$tests_dir/test_llm_client.py" << 'EOF'
"""
Test LLM client functionality.
"""

import pytest
from unittest.mock import Mock, patch
import sys
from pathlib import Path

# Add tools directory to path
sys.path.append(str(Path(__file__).parent.parent / "tools"))

from llm_client import LLMClient


class TestLLMClient:
    """Test the LLMClient class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.client = LLMClient()
    
    @patch('openai.OpenAI')
    def test_openai_client_initialization(self, mock_openai):
        """Test OpenAI client initialization."""
        with patch.dict('os.environ', {'OPENAI_API_KEY': 'test-key'}):
            client = LLMClient()
            assert client.openai_client is not None
    
    @patch('anthropic.Anthropic')
    def test_anthropic_client_initialization(self, mock_anthropic):
        """Test Anthropic client initialization."""
        with patch.dict('os.environ', {'ANTHROPIC_API_KEY': 'test-key'}):
            client = LLMClient()
            assert client.anthropic_client is not None
    
    def test_missing_api_keys(self):
        """Test handling of missing API keys."""
        with patch.dict('os.environ', {}, clear=True):
            client = LLMClient()
            assert client.openai_client is None
            assert client.anthropic_client is None
EOF

    cat > "$tests_dir/test_vector_store.py" << 'EOF'
"""
Test vector store functionality.
"""

import pytest
from unittest.mock import Mock, patch
import sys
from pathlib import Path
import tempfile
import shutil

# Add tools directory to path
sys.path.append(str(Path(__file__).parent.parent / "tools"))

from vector_store import VectorStore


class TestVectorStore:
    """Test the VectorStore class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.temp_dir = tempfile.mkdtemp()
        self.vector_store = VectorStore(
            collection_name="test_collection",
            persist_directory=self.temp_dir
        )
    
    def teardown_method(self):
        """Clean up test fixtures."""
        shutil.rmtree(self.temp_dir)
    
    def test_vector_store_initialization(self):
        """Test VectorStore initialization."""
        assert self.vector_store.collection_name == "test_collection"
        assert self.vector_store.persist_directory.exists()
    
    def test_add_documents(self):
        """Test adding documents to vector store."""
        documents = ["Test document 1", "Test document 2"]
        metadata = [{"source": "test1"}, {"source": "test2"}]
        
        # This would require actual ChromaDB setup
        # For now, just test the method exists
        assert hasattr(self.vector_store, 'add_documents')
    
    def test_search(self):
        """Test searching documents."""
        query = "test query"
        
        # This would require actual ChromaDB setup
        # For now, just test the method exists
        assert hasattr(self.vector_store, 'search')
    
    def test_get_collection_info(self):
        """Test getting collection information."""
        info = self.vector_store.get_collection_info()
        assert "name" in info
        assert "persist_directory" in info
EOF

    print_debug "Generated AI/ML tests"
}

# Generate environment files
function generate_aiml_env_files() {
    local aiml_dir="$1"
    
    # Environment template
    cat > "$aiml_dir/.env.example" << 'EOF'
# AI/ML Project Configuration

# Project settings
PROJECT_NAME="AI/ML Project"
DEBUG=True

# OpenAI Configuration
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-3.5-turbo

# Anthropic Configuration
ANTHROPIC_API_KEY=your-anthropic-api-key-here
ANTHROPIC_MODEL=claude-3-sonnet-20240229

# Google Search (optional)
GOOGLE_API_KEY=your-google-api-key-here
GOOGLE_CSE_ID=your-google-cse-id-here

# Pinecone (optional)
PINECONE_API_KEY=your-pinecone-api-key-here
PINECONE_ENVIRONMENT=your-pinecone-environment-here

# Vector Store Settings
VECTOR_STORE_TYPE=chroma
COLLECTION_NAME=documents
SIMILARITY_THRESHOLD=0.7

# Model Parameters
TEMPERATURE=0.7
MAX_TOKENS=1000
TOP_P=0.9

# Database (if using external database)
DATABASE_URL=postgresql://user:password@localhost:5432/database

# Jupyter settings
JUPYTER_TOKEN=your-jupyter-token-here
JUPYTER_PASSWORD=your-jupyter-password-here
EOF

    # Create actual .env if it doesn't exist
    if [[ ! -f "$aiml_dir/.env" ]]; then
        cp "$aiml_dir/.env.example" "$aiml_dir/.env"
    fi

    # Copy virtual environment setup script
    local setup_venv_template="$PROJECT_ROOT/templates/security/setup_venv.sh"
    if [[ -f "$setup_venv_template" ]]; then
        cp "$setup_venv_template" "$aiml_dir/setup_venv.sh"
        chmod +x "$aiml_dir/setup_venv.sh"
    fi

    # Copy Python .gitignore
    local gitignore_template="$PROJECT_ROOT/templates/security/python.gitignore"
    if [[ -f "$gitignore_template" ]]; then
        cp "$gitignore_template" "$aiml_dir/.gitignore"
        # Add AI/ML specific ignores
        cat >> "$aiml_dir/.gitignore" << 'EOF'

# AI/ML specific
.ipynb_checkpoints/
*.ipynb_checkpoints
vectorstores/
models/
data/
*.pkl
*.joblib
*.h5
*.model
*.log
*.db
*.sqlite3
chromadb/
EOF
    fi

    # Create comprehensive README
    cat > "$aiml_dir/README.md" << 'EOF'
# AI/ML Project

A comprehensive AI/ML project structure with LLM integration, vector processing, and agent workflows.

## Project Structure

```
ai-ml/
├── notebooks/          # Jupyter notebooks for experimentation
├── agents/            # AI agent implementations
├── prompts/           # Prompt templates and management
├── models/            # Trained models and model artifacts
├── vectorstores/      # Vector database storage
├── tools/             # Utility tools and clients
├── workflows/         # Automated workflows
├── data/              # Data storage
├── scripts/           # Automation scripts
└── tests/             # Unit tests
```

## Getting Started

1. **Set up environment:**
   ```bash
   ./setup_venv.sh
   source venv/bin/activate
   ```

2. **Configure API keys:**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Start Jupyter Lab:**
   ```bash
   jupyter lab
   ```

## Features

### LLM Integration
- OpenAI GPT models
- Anthropic Claude models
- Unified LLM client interface
- Prompt template management

### Vector Processing
- ChromaDB integration
- Sentence transformers
- Similarity search
- Document embeddings

### Agent Workflows
- Research agent for information gathering
- Writing agent for content creation
- Extensible agent framework
- Multi-agent conversations

### Notebooks
- `01_llm_exploration.ipynb` - LLM testing and experimentation
- `02_vector_embeddings.ipynb` - Vector embeddings and similarity search
- `03_agent_workflows.ipynb` - Agent-based workflows

## Usage Examples

### Basic LLM Chat
```python
from tools.llm_client import LLMClient

client = LLMClient()
response = client.chat_openai("Explain machine learning")
print(response)
```

### Vector Search
```python
from tools.vector_store import VectorStore

store = VectorStore("my_documents")
store.add_documents(["Document 1", "Document 2"])
results = store.search("search query")
```

### Agent Workflows
```python
from agents.research_agent import ResearchAgent

agent = ResearchAgent()
result = agent.process_message("Research the latest AI trends")
```

## Configuration

Edit `.env` file to configure:
- API keys for LLM providers
- Vector store settings
- Model parameters
- Database connections

## Scripts

- `scripts/run_agent.py` - Run interactive agent
- `scripts/chat_interface.py` - Chat interface
- `scripts/create_embeddings.py` - Create document embeddings

## Testing

Run tests with:
```bash
pytest tests/
```

## Environment Variables

Required:
- `OPENAI_API_KEY` - OpenAI API key
- `ANTHROPIC_API_KEY` - Anthropic API key

Optional:
- `GOOGLE_API_KEY` - Google Search API key
- `GOOGLE_CSE_ID` - Google Custom Search Engine ID
- `PINECONE_API_KEY` - Pinecone API key
- `PINECONE_ENVIRONMENT` - Pinecone environment

## Development

1. Add new agents in `agents/` directory
2. Create new workflows in `workflows/` directory
3. Add prompt templates in `prompts/` directory
4. Implement tools in `tools/` directory
5. Write tests in `tests/` directory
EOF

    print_debug "Generated AI/ML environment files and documentation"
}

# Main function to create AI/ML component
function create_ai_ml_component() {
    local project_dir="$1"
    
    print_info "Creating AI/ML framework component in $project_dir"
    
    generate_ai_ml_component "$project_dir"
    
    print_status "AI/ML framework component created successfully!"
    print_info "Next steps:"
    echo "  1. cd $(basename "$project_dir")/ai-ml"
    echo "  2. Set up environment: cp .env.example .env"
    echo "  3. Add your API keys to .env file"
    echo "  4. Create virtual environment: ./setup_venv.sh"
    echo "  5. Start Jupyter Lab: jupyter lab"
    echo "  6. Open notebooks/01_llm_exploration.ipynb to get started"
}

# Export functions for use by project generator
export -f generate_ai_ml_component create_ai_ml_component
export -f generate_aiml_dockerfiles generate_aiml_requirements generate_aiml_notebooks
export -f generate_aiml_agents generate_aiml_tools generate_aiml_workflows
export -f generate_aiml_config generate_aiml_tests generate_aiml_env_files