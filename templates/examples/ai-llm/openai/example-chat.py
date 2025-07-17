"""
OpenAI Chat Example
Basic chat completion with GPT-4.

Features:
- Simple chat interface
- Token usage tracking
- Cost estimation
- Error handling
- Interactive CLI

Setup:
1. pip install openai python-dotenv tiktoken
2. Set OPENAI_API_KEY environment variable
3. python example-chat.py

Environment variables:
- OPENAI_API_KEY: Your OpenAI API key
- OPENAI_MODEL: Model to use (default: gpt-4)
- OPENAI_TEMPERATURE: Response creativity (default: 0.7)
- OPENAI_MAX_TOKENS: Maximum response length (default: 1000)
"""

import os
import sys
from openai import OpenAI
from dotenv import load_dotenv
import tiktoken
from typing import List, Dict, Any, Optional
import json
import time

# Load environment variables
load_dotenv()

class OpenAIChatClient:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY environment variable is required")
        
        self.client = OpenAI(api_key=self.api_key)
        self.model = os.getenv("OPENAI_MODEL", "gpt-4")
        self.temperature = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
        self.max_tokens = int(os.getenv("OPENAI_MAX_TOKENS", "1000"))
        
        # Cost tracking
        self.total_tokens = 0
        self.total_cost = 0.0
        self.request_count = 0
        
        # Model pricing (per 1K tokens)
        self.pricing = {
            "gpt-4": 0.03,
            "gpt-4-turbo": 0.01,
            "gpt-3.5-turbo": 0.002
        }
        
        print(f"OpenAI Chat Client initialized with model: {self.model}")
        print(f"Temperature: {self.temperature}, Max tokens: {self.max_tokens}")
    
    def count_tokens(self, text: str) -> int:
        """Count tokens in text using tiktoken"""
        try:
            encoding = tiktoken.encoding_for_model(self.model)
            return len(encoding.encode(text))
        except Exception:
            # Fallback estimation
            return len(text.split()) * 1.3
    
    def calculate_cost(self, tokens: int) -> float:
        """Calculate cost based on token usage"""
        rate = self.pricing.get(self.model, 0.03)  # Default to GPT-4 pricing
        return (tokens / 1000) * rate
    
    def chat_completion(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        """Single chat completion"""
        try:
            # Count input tokens
            input_text = "\n".join([msg["content"] for msg in messages])
            input_tokens = self.count_tokens(input_text)
            
            # Make API call
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=self.temperature,
                max_tokens=self.max_tokens
            )
            
            # Extract response
            content = response.choices[0].message.content
            
            # Calculate tokens and cost
            output_tokens = self.count_tokens(content)
            total_tokens = input_tokens + output_tokens
            cost = self.calculate_cost(total_tokens)
            
            # Update tracking
            self.total_tokens += total_tokens
            self.total_cost += cost
            self.request_count += 1
            
            return {
                "content": content,
                "tokens_used": total_tokens,
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "cost": cost,
                "model": self.model
            }
            
        except Exception as e:
            return {
                "error": str(e),
                "content": None,
                "tokens_used": 0,
                "cost": 0.0
            }
    
    def chat_with_history(self, user_input: str, conversation_history: List[Dict[str, str]]) -> Dict[str, Any]:
        """Chat with conversation history"""
        # Add user message to history
        conversation_history.append({"role": "user", "content": user_input})
        
        # Get response
        result = self.chat_completion(conversation_history)
        
        # Add assistant response to history if successful
        if result["content"]:
            conversation_history.append({"role": "assistant", "content": result["content"]})
        
        return result
    
    def get_stats(self) -> Dict[str, Any]:
        """Get usage statistics"""
        return {
            "total_requests": self.request_count,
            "total_tokens": self.total_tokens,
            "total_cost": self.total_cost,
            "average_tokens_per_request": self.total_tokens / max(1, self.request_count),
            "average_cost_per_request": self.total_cost / max(1, self.request_count)
        }
    
    def reset_stats(self):
        """Reset usage statistics"""
        self.total_tokens = 0
        self.total_cost = 0.0
        self.request_count = 0

def interactive_chat():
    """Interactive chat interface"""
    print("OpenAI Chat Interface")
    print("Type 'quit' to exit, 'stats' for usage statistics, 'reset' to reset stats")
    print("Type 'help' for available commands")
    print("-" * 50)
    
    try:
        client = OpenAIChatClient()
    except Exception as e:
        print(f"Error initializing client: {e}")
        return
    
    # System prompt
    system_prompt = input("Enter system prompt (or press Enter for default): ").strip()
    if not system_prompt:
        system_prompt = "You are a helpful assistant. Be concise and informative."
    
    # Initialize conversation
    conversation = [{"role": "system", "content": system_prompt}]
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            
            if not user_input:
                continue
            
            if user_input.lower() == 'quit':
                print("Goodbye!")
                break
            
            elif user_input.lower() == 'stats':
                stats = client.get_stats()
                print(f"\nUsage Statistics:")
                print(f"Requests: {stats['total_requests']}")
                print(f"Total tokens: {stats['total_tokens']:,}")
                print(f"Total cost: ${stats['total_cost']:.4f}")
                print(f"Avg tokens/request: {stats['average_tokens_per_request']:.1f}")
                print(f"Avg cost/request: ${stats['average_cost_per_request']:.4f}")
                continue
            
            elif user_input.lower() == 'reset':
                client.reset_stats()
                print("Statistics reset!")
                continue
            
            elif user_input.lower() == 'help':
                print("\nAvailable commands:")
                print("  quit - Exit the chat")
                print("  stats - Show usage statistics")
                print("  reset - Reset statistics")
                print("  help - Show this help message")
                continue
            
            elif user_input.lower().startswith('model '):
                # Change model
                new_model = user_input[6:].strip()
                if new_model in client.pricing:
                    client.model = new_model
                    print(f"Model changed to: {new_model}")
                else:
                    print(f"Unknown model: {new_model}")
                    print(f"Available models: {list(client.pricing.keys())}")
                continue
            
            # Get AI response
            print("AI: ", end="", flush=True)
            result = client.chat_with_history(user_input, conversation)
            
            if result["error"]:
                print(f"Error: {result['error']}")
                # Remove the failed user message from history
                conversation.pop()
            else:
                print(result["content"])
                print(f"\n[Tokens: {result['tokens_used']}, Cost: ${result['cost']:.4f}]")
        
        except KeyboardInterrupt:
            print("\n\nInterrupted by user. Goodbye!")
            break
        except Exception as e:
            print(f"\nError: {e}")

def simple_chat_example():
    """Simple chat example without interaction"""
    print("Simple Chat Example")
    print("-" * 30)
    
    try:
        client = OpenAIChatClient()
    except Exception as e:
        print(f"Error: {e}")
        return
    
    # Example conversation
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is the capital of France?"}
    ]
    
    result = client.chat_completion(messages)
    
    if result["error"]:
        print(f"Error: {result['error']}")
    else:
        print(f"Question: {messages[1]['content']}")
        print(f"Answer: {result['content']}")
        print(f"Tokens used: {result['tokens_used']}")
        print(f"Cost: ${result['cost']:.4f}")

def batch_questions_example():
    """Example of processing multiple questions"""
    print("Batch Questions Example")
    print("-" * 30)
    
    try:
        client = OpenAIChatClient()
    except Exception as e:
        print(f"Error: {e}")
        return
    
    questions = [
        "What is the capital of France?",
        "How does photosynthesis work?",
        "What is the largest planet in our solar system?",
        "Explain quantum computing in simple terms."
    ]
    
    system_message = {"role": "system", "content": "You are a helpful assistant. Be concise."}
    
    for i, question in enumerate(questions, 1):
        messages = [system_message, {"role": "user", "content": question}]
        result = client.chat_completion(messages)
        
        if result["error"]:
            print(f"Question {i}: Error - {result['error']}")
        else:
            print(f"Question {i}: {question}")
            print(f"Answer: {result['content']}")
            print(f"Tokens: {result['tokens_used']}, Cost: ${result['cost']:.4f}")
        print("-" * 30)
    
    # Show final stats
    stats = client.get_stats()
    print(f"\nTotal requests: {stats['total_requests']}")
    print(f"Total tokens: {stats['total_tokens']:,}")
    print(f"Total cost: ${stats['total_cost']:.4f}")

def main():
    """Main function with options"""
    if len(sys.argv) > 1:
        if sys.argv[1] == "simple":
            simple_chat_example()
        elif sys.argv[1] == "batch":
            batch_questions_example()
        elif sys.argv[1] == "interactive":
            interactive_chat()
        else:
            print("Usage: python example-chat.py [simple|batch|interactive]")
            print("  simple - Simple Q&A example")
            print("  batch - Process multiple questions")
            print("  interactive - Interactive chat (default)")
    else:
        interactive_chat()

if __name__ == "__main__":
    main()