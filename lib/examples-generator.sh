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

# Generate Data Science example
function generate_data_science_example() {
    local project_dir="$1"
    local ds_dir="$project_dir/data-science"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would generate Data Science example"
        return 0
    fi
    
    print_info "Generating Data Science example..."
    
    # Create additional example notebooks and scripts directories
    mkdir -p "$ds_dir/notebooks"
    mkdir -p "$ds_dir/scripts"
    
    # Create example data analysis notebook
    cat > "$ds_dir/notebooks/example_analysis.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Example Data Analysis\n",
    "\n",
    "This notebook demonstrates basic data analysis workflows using pandas, numpy, and matplotlib."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "from datetime import datetime, timedelta\n",
    "\n",
    "# Set style for better plots\n",
    "plt.style.use('seaborn-v0_8')\n",
    "sns.set_palette('husl')\n",
    "\n",
    "print(\"📊 Data Science environment ready!\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Generate sample data\n",
    "np.random.seed(42)\n",
    "\n",
    "# Create sample time series data\n",
    "dates = pd.date_range(start='2023-01-01', end='2023-12-31', freq='D')\n",
    "values = np.cumsum(np.random.randn(len(dates))) + 100\n",
    "noise = np.random.normal(0, 0.5, len(dates))\n",
    "\n",
    "df = pd.DataFrame({\n",
    "    'date': dates,\n",
    "    'value': values + noise,\n",
    "    'category': np.random.choice(['A', 'B', 'C'], len(dates))\n",
    "})\n",
    "\n",
    "print(f\"📈 Generated {len(df)} data points\")\n",
    "print(df.head())"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Basic data analysis\n",
    "print(\"📊 Data Summary:\")\n",
    "print(df.describe())\n",
    "\n",
    "print(\"\\n🏷️  Category Distribution:\")\n",
    "print(df['category'].value_counts())"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create visualizations\n",
    "fig, axes = plt.subplots(2, 2, figsize=(15, 10))\n",
    "\n",
    "# Time series plot\n",
    "axes[0, 0].plot(df['date'], df['value'])\n",
    "axes[0, 0].set_title('Time Series Data')\n",
    "axes[0, 0].set_xlabel('Date')\n",
    "axes[0, 0].set_ylabel('Value')\n",
    "\n",
    "# Histogram\n",
    "axes[0, 1].hist(df['value'], bins=30, alpha=0.7)\n",
    "axes[0, 1].set_title('Value Distribution')\n",
    "axes[0, 1].set_xlabel('Value')\n",
    "axes[0, 1].set_ylabel('Frequency')\n",
    "\n",
    "# Box plot by category\n",
    "df.boxplot(column='value', by='category', ax=axes[1, 0])\n",
    "axes[1, 0].set_title('Value by Category')\n",
    "\n",
    "# Correlation heatmap (adding more features)\n",
    "df['month'] = df['date'].dt.month\n",
    "df['day_of_year'] = df['date'].dt.dayofyear\n",
    "corr_matrix = df[['value', 'month', 'day_of_year']].corr()\n",
    "sns.heatmap(corr_matrix, annot=True, ax=axes[1, 1])\n",
    "axes[1, 1].set_title('Correlation Matrix')\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Save processed data\n",
    "output_path = '../data/processed/example_analysis.csv'\n",
    "df.to_csv(output_path, index=False)\n",
    "print(f\"💾 Data saved to {output_path}\")\n",
    "\n",
    "# Generate summary report\n",
    "summary = {\n",
    "    'total_records': len(df),\n",
    "    'date_range': f\"{df['date'].min()} to {df['date'].max()}\",\n",
    "    'mean_value': df['value'].mean(),\n",
    "    'std_value': df['value'].std(),\n",
    "    'categories': df['category'].unique().tolist()\n",
    "}\n",
    "\n",
    "print(\"\\n📋 Analysis Summary:\")\n",
    "for key, value in summary.items():\n",
    "    print(f\"  {key}: {value}\")"
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
    
    # Create example Python script
    cat > "$ds_dir/scripts/data_pipeline.py" << 'EOF'
#!/usr/bin/env python3
"""
Example Data Pipeline
Demonstrates automated data processing and analysis
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_data(file_path: str) -> pd.DataFrame:
    """Load data from CSV file"""
    try:
        df = pd.read_csv(file_path)
        logger.info(f"Loaded {len(df)} records from {file_path}")
        return df
    except FileNotFoundError:
        logger.error(f"File not found: {file_path}")
        return pd.DataFrame()

def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and preprocess data"""
    # Remove duplicates
    df = df.drop_duplicates()
    
    # Handle missing values
    df = df.fillna(method='ffill')
    
    # Convert date column
    if 'date' in df.columns:
        df['date'] = pd.to_datetime(df['date'])
    
    logger.info(f"Cleaned data: {len(df)} records remaining")
    return df

def analyze_data(df: pd.DataFrame) -> dict:
    """Perform basic data analysis"""
    if df.empty:
        return {}
    
    analysis = {
        'record_count': len(df),
        'numeric_columns': df.select_dtypes(include=[np.number]).columns.tolist(),
        'categorical_columns': df.select_dtypes(include=['object']).columns.tolist(),
        'date_columns': df.select_dtypes(include=['datetime']).columns.tolist(),
        'missing_values': df.isnull().sum().to_dict(),
        'summary_stats': df.describe().to_dict() if len(df.select_dtypes(include=[np.number]).columns) > 0 else {}
    }
    
    return analysis

def generate_visualizations(df: pd.DataFrame, output_dir: str):
    """Generate and save visualizations"""
    if df.empty:
        return
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    
    if len(numeric_cols) > 0:
        # Create distribution plots
        fig, axes = plt.subplots(len(numeric_cols), 1, figsize=(10, 4 * len(numeric_cols)))
        if len(numeric_cols) == 1:
            axes = [axes]
        
        for i, col in enumerate(numeric_cols):
            axes[i].hist(df[col], bins=30, alpha=0.7)
            axes[i].set_title(f'Distribution of {col}')
            axes[i].set_xlabel(col)
            axes[i].set_ylabel('Frequency')
        
        plt.tight_layout()
        plt.savefig(output_path / 'distributions.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        logger.info(f"Visualizations saved to {output_path}")

def main():
    """Main pipeline execution"""
    logger.info("Starting data pipeline...")
    
    # Define paths
    data_dir = Path("../data")
    raw_data_path = data_dir / "raw" / "sample_data.csv"
    processed_data_path = data_dir / "processed" / "cleaned_data.csv"
    reports_dir = data_dir.parent / "reports"
    
    # Create directories if they don't exist
    for path in [data_dir / "raw", data_dir / "processed", reports_dir]:
        path.mkdir(parents=True, exist_ok=True)
    
    # Generate sample data if it doesn't exist
    if not raw_data_path.exists():
        logger.info("Generating sample data...")
        np.random.seed(42)
        sample_data = pd.DataFrame({
            'date': pd.date_range('2023-01-01', periods=1000, freq='D'),
            'value': np.cumsum(np.random.randn(1000)) + 100,
            'category': np.random.choice(['A', 'B', 'C'], 1000),
            'amount': np.random.uniform(10, 1000, 1000)
        })
        sample_data.to_csv(raw_data_path, index=False)
        logger.info(f"Sample data created at {raw_data_path}")
    
    # Load and process data
    df = load_data(raw_data_path)
    if df.empty:
        logger.error("No data to process")
        return
    
    # Clean data
    df_clean = clean_data(df)
    
    # Analyze data
    analysis = analyze_data(df_clean)
    
    # Save cleaned data
    df_clean.to_csv(processed_data_path, index=False)
    logger.info(f"Cleaned data saved to {processed_data_path}")
    
    # Generate visualizations
    generate_visualizations(df_clean, reports_dir)
    
    # Save analysis report
    report_path = reports_dir / f"analysis_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    with open(report_path, 'w') as f:
        f.write("Data Analysis Report\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Generated on: {datetime.now()}\n\n")
        
        for key, value in analysis.items():
            f.write(f"{key.replace('_', ' ').title()}:\n")
            f.write(f"  {value}\n\n")
    
    logger.info(f"Analysis report saved to {report_path}")
    logger.info("Pipeline completed successfully!")

if __name__ == "__main__":
    main()
EOF
    
    print_status "Generated Data Science example in $ds_dir"
}

# Generate AI/ML example
function generate_ai_ml_example() {
    local project_dir="$1"
    local aiml_dir="$project_dir/ai-ml"
    
    if [[ "$WITH_EXAMPLES" != "true" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would generate AI/ML example"
        return 0
    fi
    
    print_info "Generating AI/ML example..."
    
    # Create additional example workflows and agents directories
    mkdir -p "$aiml_dir/workflows"
    mkdir -p "$aiml_dir/agents"
    
    # Create example agent workflow
    cat > "$aiml_dir/agents/research_agent.py" << 'EOF'
#!/usr/bin/env python3
"""
Research Agent Example
Demonstrates an AI agent that can research topics and generate reports
"""

import os
import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path

# LLM Client imports (example - adjust based on your preferred provider)
try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

try:
    import anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False

class ResearchAgent:
    """AI Agent for conducting research and generating reports"""
    
    def __init__(self, provider: str = "openai", model: str = None):
        self.provider = provider.lower()
        self.model = model or self._get_default_model()
        self.client = self._initialize_client()
        self.conversation_history = []
        
    def _get_default_model(self) -> str:
        """Get default model based on provider"""
        defaults = {
            "openai": "gpt-4",
            "anthropic": "claude-3-sonnet-20240229"
        }
        return defaults.get(self.provider, "gpt-4")
    
    def _initialize_client(self):
        """Initialize the LLM client"""
        if self.provider == "openai" and OPENAI_AVAILABLE:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable is required")
            return OpenAI(api_key=api_key)
        
        elif self.provider == "anthropic" and ANTHROPIC_AVAILABLE:
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                raise ValueError("ANTHROPIC_API_KEY environment variable is required")
            return anthropic.Anthropic(api_key=api_key)
        
        else:
            raise ValueError(f"Provider {self.provider} not supported or not installed")
    
    def generate_response(self, prompt: str, system_prompt: str = None) -> str:
        """Generate response using configured LLM"""
        try:
            if self.provider == "openai":
                messages = []
                if system_prompt:
                    messages.append({"role": "system", "content": system_prompt})
                messages.append({"role": "user", "content": prompt})
                
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    max_tokens=2000,
                    temperature=0.7
                )
                return response.choices[0].message.content
            
            elif self.provider == "anthropic":
                response = self.client.messages.create(
                    model=self.model,
                    max_tokens=2000,
                    system=system_prompt or "You are a helpful research assistant.",
                    messages=[{"role": "user", "content": prompt}]
                )
                return response.content[0].text
            
        except Exception as e:
            return f"Error generating response: {str(e)}"
    
    def research_topic(self, topic: str, depth: str = "medium") -> Dict[str, Any]:
        """Research a topic and return structured findings"""
        system_prompt = """You are a research assistant. Provide comprehensive, accurate information about the given topic. 
        Structure your response with:
        1. Overview
        2. Key Points (3-5 main points)
        3. Current Trends
        4. Implications
        5. References/Sources to explore further
        
        Be factual and cite your reasoning."""
        
        research_prompt = f"""
        Research the topic: {topic}
        
        Depth level: {depth}
        
        Please provide a comprehensive analysis covering the key aspects, current state, 
        and implications of this topic. Focus on accuracy and practical insights.
        """
        
        response = self.generate_response(research_prompt, system_prompt)
        
        # Structure the response
        research_result = {
            "topic": topic,
            "depth": depth,
            "timestamp": datetime.now().isoformat(),
            "content": response,
            "agent_info": {
                "provider": self.provider,
                "model": self.model
            }
        }
        
        return research_result
    
    def generate_report(self, research_data: Dict[str, Any], format: str = "markdown") -> str:
        """Generate a formatted report from research data"""
        system_prompt = f"""You are a report writer. Convert the research data into a well-formatted {format} report.
        
        Include:
        - Executive Summary
        - Detailed Analysis
        - Key Findings
        - Recommendations
        - Conclusion
        
        Use proper {format} formatting."""
        
        report_prompt = f"""
        Generate a professional {format} report based on this research data:
        
        Topic: {research_data['topic']}
        Research Content: {research_data['content']}
        
        Create a comprehensive, well-structured report suitable for presentation.
        """
        
        return self.generate_response(report_prompt, system_prompt)
    
    def save_research(self, research_data: Dict[str, Any], output_dir: str = "../reports"):
        """Save research data to file"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save raw research data
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        topic_slug = research_data['topic'].lower().replace(' ', '_').replace('/', '_')
        
        json_file = output_path / f"{topic_slug}_research_{timestamp}.json"
        with open(json_file, 'w') as f:
            json.dump(research_data, f, indent=2)
        
        # Generate and save report
        report_content = self.generate_report(research_data)
        report_file = output_path / f"{topic_slug}_report_{timestamp}.md"
        
        with open(report_file, 'w') as f:
            f.write(report_content)
        
        return {
            "research_file": str(json_file),
            "report_file": str(report_file)
        }

def main():
    """Example usage of the Research Agent"""
    print("🤖 Starting Research Agent Example...")
    
    # Initialize agent (defaults to OpenAI, falls back to Anthropic)
    try:
        if OPENAI_AVAILABLE and os.getenv("OPENAI_API_KEY"):
            agent = ResearchAgent(provider="openai")
        elif ANTHROPIC_AVAILABLE and os.getenv("ANTHROPIC_API_KEY"):
            agent = ResearchAgent(provider="anthropic")
        else:
            print("❌ No API keys found. Please set OPENAI_API_KEY or ANTHROPIC_API_KEY")
            print("📝 Example output will be generated instead...")
            
            # Generate example output
            example_research = {
                "topic": "Machine Learning in Healthcare",
                "depth": "medium",
                "timestamp": datetime.now().isoformat(),
                "content": "Machine Learning in healthcare is revolutionizing patient care through predictive analytics, diagnostic assistance, and personalized treatment plans. Key areas include medical imaging analysis, drug discovery, and electronic health record optimization.",
                "agent_info": {
                    "provider": "example",
                    "model": "example-model"
                }
            }
            
            output_dir = Path("../reports")
            output_dir.mkdir(parents=True, exist_ok=True)
            
            with open(output_dir / "example_research.json", 'w') as f:
                json.dump(example_research, f, indent=2)
                
            print("📁 Example research data saved to ../reports/example_research.json")
            return
    
    except Exception as e:
        print(f"❌ Error initializing agent: {e}")
        return
    
    # Example research topic
    topic = "Artificial Intelligence in Climate Change Solutions"
    
    print(f"🔍 Researching topic: {topic}")
    
    # Conduct research
    research_data = agent.research_topic(topic, depth="medium")
    
    # Save research and generate report
    files = agent.save_research(research_data)
    
    print(f"✅ Research completed!")
    print(f"📄 Research data: {files['research_file']}")
    print(f"📋 Report: {files['report_file']}")

if __name__ == "__main__":
    main()
EOF
    
    # Create example workflow script
    cat > "$aiml_dir/workflows/document_processor.py" << 'EOF'
#!/usr/bin/env python3
"""
Document Processing Workflow
Demonstrates AI-powered document analysis and processing
"""

import os
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional

# Vector store imports
try:
    import chromadb
    CHROMA_AVAILABLE = True
except ImportError:
    CHROMA_AVAILABLE = False

# Text processing imports
try:
    from sentence_transformers import SentenceTransformer
    SENTENCE_TRANSFORMERS_AVAILABLE = True
except ImportError:
    SENTENCE_TRANSFORMERS_AVAILABLE = False

class DocumentProcessor:
    """AI-powered document processor with vector search capabilities"""
    
    def __init__(self, collection_name: str = "documents"):
        self.collection_name = collection_name
        self.client = None
        self.collection = None
        self.embeddings_model = None
        
        self._initialize_vector_store()
        self._initialize_embeddings()
    
    def _initialize_vector_store(self):
        """Initialize Chroma vector store"""
        if not CHROMA_AVAILABLE:
            print("⚠️  Chroma not available. Vector search will be disabled.")
            return
        
        try:
            # Initialize Chroma client
            self.client = chromadb.Client()
            
            # Get or create collection
            self.collection = self.client.get_or_create_collection(
                name=self.collection_name,
                metadata={"description": "Document embeddings for search"}
            )
            print(f"✅ Vector store initialized: {self.collection_name}")
            
        except Exception as e:
            print(f"❌ Error initializing vector store: {e}")
    
    def _initialize_embeddings(self):
        """Initialize embeddings model"""
        if not SENTENCE_TRANSFORMERS_AVAILABLE:
            print("⚠️  Sentence Transformers not available. Using mock embeddings.")
            return
        
        try:
            # Use a lightweight model for demonstration
            self.embeddings_model = SentenceTransformer('all-MiniLM-L6-v2')
            print("✅ Embeddings model loaded")
            
        except Exception as e:
            print(f"❌ Error loading embeddings model: {e}")
    
    def extract_text_from_file(self, file_path: str) -> str:
        """Extract text from various file formats"""
        file_path = Path(file_path)
        
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        if file_path.suffix.lower() == '.txt':
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        
        elif file_path.suffix.lower() == '.json':
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return json.dumps(data, indent=2)
        
        else:
            # For other formats, read as text (basic implementation)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    return f.read()
            except UnicodeDecodeError:
                return f"Binary file: {file_path.name} (content not readable as text)"
    
    def chunk_text(self, text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
        """Split text into overlapping chunks"""
        chunks = []
        start = 0
        
        while start < len(text):
            end = start + chunk_size
            chunk = text[start:end]
            
            # Try to end at a sentence boundary
            if end < len(text):
                last_period = chunk.rfind('.')
                last_newline = chunk.rfind('\n')
                boundary = max(last_period, last_newline)
                
                if boundary > start + chunk_size // 2:
                    chunk = text[start:start + boundary + 1]
                    end = start + boundary + 1
            
            chunks.append(chunk.strip())
            start = end - overlap
        
        return [chunk for chunk in chunks if chunk]
    
    def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for text chunks"""
        if not self.embeddings_model:
            # Return mock embeddings if model not available
            return [[0.0] * 384 for _ in texts]
        
        try:
            embeddings = self.embeddings_model.encode(texts)
            return embeddings.tolist()
        except Exception as e:
            print(f"❌ Error generating embeddings: {e}")
            return [[0.0] * 384 for _ in texts]
    
    def add_document(self, file_path: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """Add document to vector store"""
        file_path = Path(file_path)
        
        # Extract text
        text = self.extract_text_from_file(file_path)
        
        # Chunk text
        chunks = self.chunk_text(text)
        
        # Generate embeddings
        embeddings = self.generate_embeddings(chunks)
        
        # Prepare metadata
        base_metadata = {
            "filename": file_path.name,
            "filepath": str(file_path),
            "file_size": file_path.stat().st_size,
            "modified_time": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
            "processed_time": datetime.now().isoformat(),
            "num_chunks": len(chunks)
        }
        
        if metadata:
            base_metadata.update(metadata)
        
        # Add to vector store
        if self.collection:
            try:
                # Create unique IDs for each chunk
                ids = [f"{file_path.stem}_{i}" for i in range(len(chunks))]
                
                # Add chunk metadata
                chunk_metadata = []
                for i, chunk in enumerate(chunks):
                    chunk_meta = base_metadata.copy()
                    chunk_meta.update({
                        "chunk_id": i,
                        "chunk_text": chunk[:100] + "..." if len(chunk) > 100 else chunk
                    })
                    chunk_metadata.append(chunk_meta)
                
                self.collection.add(
                    embeddings=embeddings,
                    documents=chunks,
                    metadatas=chunk_metadata,
                    ids=ids
                )
                
                print(f"✅ Added {len(chunks)} chunks from {file_path.name}")
                
            except Exception as e:
                print(f"❌ Error adding to vector store: {e}")
        
        return {
            "filename": file_path.name,
            "chunks": len(chunks),
            "total_chars": len(text),
            "metadata": base_metadata
        }
    
    def search_documents(self, query: str, n_results: int = 5) -> List[Dict[str, Any]]:
        """Search documents using vector similarity"""
        if not self.collection:
            return []
        
        try:
            # Generate query embedding
            query_embedding = self.generate_embeddings([query])[0]
            
            # Search vector store
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=n_results
            )
            
            # Format results
            formatted_results = []
            for i in range(len(results['documents'][0])):
                formatted_results.append({
                    "document": results['documents'][0][i],
                    "metadata": results['metadatas'][0][i],
                    "distance": results['distances'][0][i] if 'distances' in results else 0.0
                })
            
            return formatted_results
            
        except Exception as e:
            print(f"❌ Error searching documents: {e}")
            return []
    
    def process_directory(self, directory_path: str, file_extensions: List[str] = None) -> Dict[str, Any]:
        """Process all files in a directory"""
        directory_path = Path(directory_path)
        
        if not directory_path.exists():
            raise FileNotFoundError(f"Directory not found: {directory_path}")
        
        if file_extensions is None:
            file_extensions = ['.txt', '.json', '.md', '.py', '.js', '.html', '.css']
        
        results = {
            "directory": str(directory_path),
            "processed_files": [],
            "errors": [],
            "total_chunks": 0,
            "total_characters": 0
        }
        
        for file_path in directory_path.rglob('*'):
            if file_path.is_file() and file_path.suffix.lower() in file_extensions:
                try:
                    file_result = self.add_document(file_path)
                    results["processed_files"].append(file_result)
                    results["total_chunks"] += file_result["chunks"]
                    results["total_characters"] += file_result["total_chars"]
                    
                except Exception as e:
                    results["errors"].append({
                        "file": str(file_path),
                        "error": str(e)
                    })
        
        return results

def main():
    """Example usage of the Document Processor"""
    print("📚 Starting Document Processing Workflow...")
    
    # Initialize processor
    processor = DocumentProcessor()
    
    # Create example documents
    examples_dir = Path("../examples")
    examples_dir.mkdir(parents=True, exist_ok=True)
    
    # Create sample documents
    sample_docs = {
        "research_notes.txt": """
        Research Notes on AI Applications
        
        Machine learning is transforming various industries including healthcare, finance, and education.
        Key applications include:
        
        1. Healthcare: Diagnostic imaging, drug discovery, personalized medicine
        2. Finance: Fraud detection, algorithmic trading, risk assessment
        3. Education: Personalized learning, automated grading, content generation
        
        Recent trends show increasing adoption of transformer models and large language models.
        Ethical considerations include bias, privacy, and transparency.
        """,
        
        "project_overview.md": """
        # AI Project Overview
        
        ## Objectives
        - Develop intelligent document processing system
        - Implement semantic search capabilities
        - Create automated analysis workflows
        
        ## Technology Stack
        - Python 3.12+
        - ChromaDB for vector storage
        - Sentence Transformers for embeddings
        - OpenAI/Anthropic APIs for LLM integration
        
        ## Key Features
        - Multi-format document support
        - Chunked text processing
        - Vector similarity search
        - Batch processing capabilities
        """,
        
        "config.json": json.dumps({
            "embedding_model": "all-MiniLM-L6-v2",
            "chunk_size": 500,
            "chunk_overlap": 50,
            "max_results": 10,
            "supported_formats": [".txt", ".md", ".json", ".py", ".js"]
        }, indent=2)
    }
    
    # Write sample documents
    for filename, content in sample_docs.items():
        doc_path = examples_dir / filename
        with open(doc_path, 'w') as f:
            f.write(content)
        
        # Process the document
        result = processor.add_document(doc_path)
        print(f"📄 Processed {filename}: {result['chunks']} chunks")
    
    # Example search
    print("\n🔍 Searching documents...")
    
    search_queries = [
        "machine learning applications",
        "technology stack",
        "ethical considerations"
    ]
    
    for query in search_queries:
        results = processor.search_documents(query, n_results=3)
        print(f"\n📋 Query: '{query}'")
        
        for i, result in enumerate(results, 1):
            print(f"  {i}. {result['metadata']['filename']} (chunk {result['metadata']['chunk_id']})")
            print(f"     Preview: {result['document'][:100]}...")
    
    print("\n✅ Document processing workflow completed!")

if __name__ == "__main__":
    main()
EOF
    
    print_status "Generated AI/ML example in $aiml_dir"
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
    
    # Ensure project directory exists
    mkdir -p "$project_dir"
    
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
        "data-science")
            generate_data_science_example "$project_dir"
            ;;
        "ai-ml")
            generate_ai_ml_example "$project_dir"
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