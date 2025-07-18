#!/usr/bin/env python3
"""
LangChain Agent Example

This example demonstrates how to create and use LangChain agents
with tools for multi-step reasoning and function calling.
"""

import os
import sys
from typing import List, Dict, Any, Optional
from langchain.agents import Tool, initialize_agent, AgentType
from langchain.chat_models import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain.tools import DuckDuckGoSearchRun
from langchain.utilities import WikipediaAPIWrapper
from langchain.schema import BaseMessage
from dotenv import load_dotenv
import requests
import json
from datetime import datetime

# Load environment variables
load_dotenv()

class CustomTools:
    """Custom tools for the LangChain agent."""
    
    @staticmethod
    def calculator(expression: str) -> str:
        """Simple calculator tool."""
        try:
            # Basic safety check
            allowed_chars = set('0123456789+-*/().')
            if not all(c in allowed_chars for c in expression.replace(' ', '')):
                return "Error: Invalid characters in expression"
            
            result = eval(expression)
            return f"Result: {result}"
        except Exception as e:
            return f"Error: {str(e)}"
    
    @staticmethod
    def current_time() -> str:
        """Get current time."""
        return f"Current time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    
    @staticmethod
    def weather_info(location: str) -> str:
        """Get weather information (mock implementation)."""
        # In a real implementation, this would call a weather API
        mock_weather = {
            "temperature": "72°F",
            "condition": "Sunny",
            "humidity": "45%",
            "wind": "8 mph"
        }
        return f"Weather in {location}: {mock_weather['temperature']}, {mock_weather['condition']}, Humidity: {mock_weather['humidity']}, Wind: {mock_weather['wind']}"
    
    @staticmethod
    def word_count(text: str) -> str:
        """Count words in text."""
        words = len(text.split())
        chars = len(text)
        return f"Word count: {words} words, {chars} characters"

class LangChainAgent:
    """LangChain agent with multiple tools."""
    
    def __init__(self):
        """Initialize the agent."""
        # Check for API key
        self.openai_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_key:
            raise ValueError("OPENAI_API_KEY is required")
        
        # Initialize LLM
        self.llm = ChatOpenAI(
            api_key=self.openai_key,
            model_name="gpt-3.5-turbo",
            temperature=0.3,
            max_tokens=1500
        )
        
        # Initialize memory
        self.memory = ConversationBufferMemory(
            memory_key="chat_history",
            return_messages=True
        )
        
        # Initialize tools
        self.tools = self._create_tools()
        
        # Initialize agent
        self.agent = initialize_agent(
            tools=self.tools,
            llm=self.llm,
            agent=AgentType.CHAT_CONVERSATIONAL_REACT_DESCRIPTION,
            memory=self.memory,
            verbose=True,
            max_iterations=5,
            early_stopping_method="generate"
        )
    
    def _create_tools(self) -> List[Tool]:
        """Create the tools for the agent."""
        tools = []
        
        # Calculator tool
        tools.append(Tool(
            name="Calculator",
            func=CustomTools.calculator,
            description="Useful for mathematical calculations. Input should be a mathematical expression."
        ))
        
        # Time tool
        tools.append(Tool(
            name="CurrentTime",
            func=CustomTools.current_time,
            description="Get the current date and time."
        ))
        
        # Weather tool
        tools.append(Tool(
            name="Weather",
            func=CustomTools.weather_info,
            description="Get weather information for a location. Input should be a city name."
        ))
        
        # Word count tool
        tools.append(Tool(
            name="WordCount",
            func=CustomTools.word_count,
            description="Count words and characters in text. Input should be the text to count."
        ))
        
        # Try to add search tools if available
        try:
            # DuckDuckGo search
            search = DuckDuckGoSearchRun()
            tools.append(Tool(
                name="Search",
                func=search.run,
                description="Search the internet for current information. Input should be a search query."
            ))
        except Exception as e:
            print(f"⚠️ Search tool not available: {str(e)}")
        
        try:
            # Wikipedia search
            wikipedia = WikipediaAPIWrapper()
            tools.append(Tool(
                name="Wikipedia",
                func=wikipedia.run,
                description="Search Wikipedia for information. Input should be a search query."
            ))
        except Exception as e:
            print(f"⚠️ Wikipedia tool not available: {str(e)}")
        
        return tools
    
    def run(self, query: str) -> str:
        """Run the agent with a query."""
        try:
            result = self.agent.run(query)
            return result
        except Exception as e:
            return f"Error: {str(e)}"
    
    def get_tools_info(self) -> Dict[str, Any]:
        """Get information about available tools."""
        return {
            "tools": [{"name": tool.name, "description": tool.description} for tool in self.tools],
            "total_tools": len(self.tools)
        }
    
    def clear_memory(self):
        """Clear the conversation memory."""
        self.memory.clear()
        print("🧹 Memory cleared")

def main():
    """Main function demonstrating LangChain agent."""
    print("🤖 LangChain Agent Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set")
        print("Please set your OpenAI API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize agent
        print("🔄 Initializing LangChain agent...")
        agent = LangChainAgent()
        
        # Show available tools
        tools_info = agent.get_tools_info()
        print(f"✅ Agent initialized with {tools_info['total_tools']} tools:")
        for tool in tools_info['tools']:
            print(f"  - {tool['name']}: {tool['description']}")
        
        print("\n" + "-" * 50)
        print("🤖 Agent Ready! Ask questions that might require tool usage.")
        print("Type 'quit' to exit, 'clear' to clear memory, 'tools' to see available tools")
        print("Example queries:")
        print("  - 'What is 25 * 47 + 123?'")
        print("  - 'What time is it?'")
        print("  - 'What's the weather like in Paris?'")
        print("  - 'How many words are in this sentence?'")
        print("  - 'Search for recent news about AI'")
        print("-" * 50)
        
        while True:
            # Get user input
            user_input = input("\n🧑 You: ").strip()
            
            # Handle special commands
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'clear':
                agent.clear_memory()
                continue
            elif user_input.lower() == 'tools':
                tools_info = agent.get_tools_info()
                print(f"\n🔧 Available tools ({tools_info['total_tools']}):")
                for tool in tools_info['tools']:
                    print(f"  - {tool['name']}: {tool['description']}")
                continue
            elif not user_input:
                continue
            
            # Run the agent
            print("🤖 Agent: ", end="", flush=True)
            result = agent.run(user_input)
            print(f"\n{result}")
            
    except KeyboardInterrupt:
        print("\n\n👋 Agent interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()