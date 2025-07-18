#!/usr/bin/env python3
"""
Anthropic Claude Function Calling Example

This example demonstrates how to use Claude's function calling capabilities
to integrate with external APIs and perform structured tasks.
"""

import os
import json
import sys
from typing import List, Dict, Any, Optional
from anthropic import Anthropic
from dotenv import load_dotenv
import requests
from datetime import datetime

# Load environment variables
load_dotenv()

class WeatherAPI:
    """Mock weather API for demonstration."""
    
    @staticmethod
    def get_weather(location: str) -> Dict[str, Any]:
        """Get current weather for a location."""
        # In a real implementation, this would call an actual weather API
        mock_data = {
            "location": location,
            "temperature": 72,
            "condition": "Sunny",
            "humidity": 45,
            "wind_speed": 8,
            "timestamp": datetime.now().isoformat()
        }
        return mock_data
    
    @staticmethod
    def get_forecast(location: str, days: int = 5) -> List[Dict[str, Any]]:
        """Get weather forecast for a location."""
        # Mock forecast data
        forecast = []
        for i in range(days):
            forecast.append({
                "day": i + 1,
                "location": location,
                "temperature_high": 75 + i,
                "temperature_low": 55 + i,
                "condition": "Partly Cloudy" if i % 2 == 0 else "Sunny",
                "precipitation_chance": 20 + (i * 10)
            })
        return forecast

class ClaudeFunctionCalling:
    """Claude client with function calling capabilities."""
    
    def __init__(self, api_key: str = None):
        """Initialize the Claude client."""
        self.api_key = api_key or os.getenv("ANTHROPIC_API_KEY")
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY is required")
        
        self.client = Anthropic(api_key=self.api_key)
        self.weather_api = WeatherAPI()
        
        # Configuration
        self.model = os.getenv("ANTHROPIC_MODEL", "claude-3-sonnet-20240229")
        self.max_tokens = int(os.getenv("ANTHROPIC_MAX_TOKENS", "1024"))
        
        # Define available functions
        self.functions = {
            "get_weather": {
                "description": "Get current weather information for a location",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {
                            "type": "string",
                            "description": "The city and state/country, e.g. San Francisco, CA"
                        }
                    },
                    "required": ["location"]
                }
            },
            "get_forecast": {
                "description": "Get weather forecast for a location",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {
                            "type": "string",
                            "description": "The city and state/country, e.g. San Francisco, CA"
                        },
                        "days": {
                            "type": "integer",
                            "description": "Number of days to forecast (1-7)",
                            "minimum": 1,
                            "maximum": 7
                        }
                    },
                    "required": ["location"]
                }
            }
        }
    
    def execute_function(self, function_name: str, arguments: Dict[str, Any]) -> Any:
        """Execute a function call."""
        try:
            if function_name == "get_weather":
                return self.weather_api.get_weather(arguments["location"])
            elif function_name == "get_forecast":
                days = arguments.get("days", 5)
                return self.weather_api.get_forecast(arguments["location"], days)
            else:
                raise ValueError(f"Unknown function: {function_name}")
        except Exception as e:
            return {"error": f"Function execution failed: {str(e)}"}
    
    def chat_with_functions(self, message: str) -> str:
        """Chat with Claude using function calling."""
        try:
            # Create the message with function definitions
            messages = [{"role": "user", "content": message}]
            
            # Note: As of the current Anthropic API, function calling is implemented
            # differently than OpenAI. This is a conceptual example showing how
            # you might structure function calling with Claude.
            
            # First, ask Claude to identify if a function should be called
            function_prompt = f"""
            You are an AI assistant with access to weather functions. 
            
            Available functions:
            {json.dumps(self.functions, indent=2)}
            
            User message: {message}
            
            If the user is asking for weather information, respond with a JSON object containing:
            {{
                "needs_function": true,
                "function_name": "function_name",
                "arguments": {{...}}
            }}
            
            If no function is needed, respond with:
            {{
                "needs_function": false,
                "response": "your normal response"
            }}
            """
            
            response = self.client.messages.create(
                model=self.model,
                max_tokens=self.max_tokens,
                messages=[{"role": "user", "content": function_prompt}]
            )
            
            response_text = response.content[0].text
            
            # Try to parse as JSON to see if function calling is needed
            try:
                response_data = json.loads(response_text)
                
                if response_data.get("needs_function"):
                    # Execute the function
                    function_name = response_data["function_name"]
                    arguments = response_data["arguments"]
                    
                    print(f"🔧 Executing function: {function_name}({arguments})")
                    function_result = self.execute_function(function_name, arguments)
                    
                    # Ask Claude to format the result
                    format_prompt = f"""
                    The user asked: {message}
                    
                    I called the function {function_name} with arguments {arguments}
                    and got this result: {json.dumps(function_result, indent=2)}
                    
                    Please provide a natural, helpful response to the user based on this data.
                    """
                    
                    final_response = self.client.messages.create(
                        model=self.model,
                        max_tokens=self.max_tokens,
                        messages=[{"role": "user", "content": format_prompt}]
                    )
                    
                    return final_response.content[0].text
                else:
                    return response_data.get("response", "I'm not sure how to help with that.")
                    
            except json.JSONDecodeError:
                # If it's not JSON, treat as a regular response
                return response_text
                
        except Exception as e:
            return f"Error: {str(e)}"

def main():
    """Main function demonstrating Claude function calling."""
    print("🤖 Anthropic Claude Function Calling Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("❌ Error: ANTHROPIC_API_KEY environment variable is not set")
        print("Please set your Anthropic API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize the function calling client
        claude_client = ClaudeFunctionCalling()
        print(f"✅ Connected to Claude with function calling capabilities")
        print("Available functions: get_weather, get_forecast")
        print("Try asking: 'What's the weather in San Francisco?'")
        print("Type 'quit' to exit")
        print("-" * 50)
        
        while True:
            # Get user input
            user_input = input("\n🧑 You: ").strip()
            
            # Handle quit command
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif not user_input:
                continue
            
            # Process with function calling
            print("🤖 Claude: ", end="", flush=True)
            response = claude_client.chat_with_functions(user_input)
            print(response)
            
    except KeyboardInterrupt:
        print("\n\n👋 Chat interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()