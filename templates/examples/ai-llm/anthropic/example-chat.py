#!/usr/bin/env python3
"""
Anthropic Claude Chat Example

This example demonstrates how to integrate Anthropic's Claude API
for basic chat functionality with proper error handling and configuration.
"""

import os
import sys
from typing import List, Dict, Any
from anthropic import Anthropic
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class ClaudeChat:
    """Simple Claude chat client with conversation history."""
    
    def __init__(self, api_key: str = None):
        """Initialize the Claude client."""
        self.api_key = api_key or os.getenv("ANTHROPIC_API_KEY")
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY is required")
        
        self.client = Anthropic(api_key=self.api_key)
        self.conversation_history: List[Dict[str, str]] = []
        
        # Configuration from environment variables
        self.model = os.getenv("ANTHROPIC_MODEL", "claude-3-sonnet-20240229")
        self.max_tokens = int(os.getenv("ANTHROPIC_MAX_TOKENS", "1024"))
        self.temperature = float(os.getenv("ANTHROPIC_TEMPERATURE", "0.7"))
    
    def chat(self, message: str) -> str:
        """Send a message to Claude and get response."""
        try:
            # Add user message to conversation history
            self.conversation_history.append({"role": "user", "content": message})
            
            # Create the API request
            response = self.client.messages.create(
                model=self.model,
                max_tokens=self.max_tokens,
                temperature=self.temperature,
                messages=self.conversation_history
            )
            
            # Extract the response text
            response_text = response.content[0].text
            
            # Add assistant response to conversation history
            self.conversation_history.append({"role": "assistant", "content": response_text})
            
            return response_text
            
        except Exception as e:
            error_msg = f"Error communicating with Claude: {str(e)}"
            print(f"🚨 {error_msg}")
            return error_msg
    
    def clear_history(self):
        """Clear the conversation history."""
        self.conversation_history = []
        print("🧹 Conversation history cleared")
    
    def get_conversation_summary(self) -> Dict[str, Any]:
        """Get a summary of the current conversation."""
        return {
            "total_messages": len(self.conversation_history),
            "user_messages": len([m for m in self.conversation_history if m["role"] == "user"]),
            "assistant_messages": len([m for m in self.conversation_history if m["role"] == "assistant"]),
            "model": self.model,
            "max_tokens": self.max_tokens,
            "temperature": self.temperature
        }

def main():
    """Main function demonstrating Claude chat functionality."""
    print("🤖 Anthropic Claude Chat Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("❌ Error: ANTHROPIC_API_KEY environment variable is not set")
        print("Please set your Anthropic API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize the chat client
        chat_client = ClaudeChat()
        print(f"✅ Connected to Claude ({chat_client.model})")
        print("Type 'quit' to exit, 'clear' to clear history, 'summary' for conversation summary")
        print("-" * 50)
        
        while True:
            # Get user input
            user_input = input("\n🧑 You: ").strip()
            
            # Handle special commands
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'clear':
                chat_client.clear_history()
                continue
            elif user_input.lower() == 'summary':
                summary = chat_client.get_conversation_summary()
                print(f"\n📊 Conversation Summary:")
                for key, value in summary.items():
                    print(f"   {key}: {value}")
                continue
            elif not user_input:
                continue
            
            # Send message to Claude
            print("🤖 Claude: ", end="", flush=True)
            response = chat_client.chat(user_input)
            print(response)
            
    except KeyboardInterrupt:
        print("\n\n👋 Chat interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()