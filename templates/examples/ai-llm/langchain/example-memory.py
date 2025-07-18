#!/usr/bin/env python3
"""
LangChain Memory Example

This example demonstrates different types of memory components
in LangChain for maintaining conversation context and history.
"""

import os
import sys
from typing import List, Dict, Any, Optional
from langchain.chat_models import ChatOpenAI
from langchain.memory import (
    ConversationBufferMemory,
    ConversationBufferWindowMemory,
    ConversationSummaryMemory,
    ConversationSummaryBufferMemory,
    ConversationKGMemory
)
from langchain.chains import ConversationChain
from langchain.prompts import PromptTemplate
from langchain.schema import BaseMessage
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class MemoryDemo:
    """Demonstration of different LangChain memory types."""
    
    def __init__(self):
        """Initialize the memory demo."""
        # Check for API key
        self.openai_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_key:
            raise ValueError("OPENAI_API_KEY is required")
        
        # Initialize LLM
        self.llm = ChatOpenAI(
            api_key=self.openai_key,
            model_name="gpt-3.5-turbo",
            temperature=0.7,
            max_tokens=1024
        )
        
        # Initialize different memory types
        self.memory_types = {
            "buffer": ConversationBufferMemory(return_messages=True),
            "buffer_window": ConversationBufferWindowMemory(k=3, return_messages=True),
            "summary": ConversationSummaryMemory(llm=self.llm, return_messages=True),
            "summary_buffer": ConversationSummaryBufferMemory(
                llm=self.llm, 
                max_token_limit=300,
                return_messages=True
            )
        }
        
        # Initialize conversation chains
        self.chains = {}
        self._create_chains()
    
    def _create_chains(self):
        """Create conversation chains with different memory types."""
        # Custom prompt template
        template = """The following is a friendly conversation between a human and an AI. 
        The AI is talkative and provides lots of specific details from its context. 
        If the AI does not know the answer to a question, it truthfully says it does not know.

        Current conversation:
        {history}
        Human: {input}
        AI:"""
        
        prompt = PromptTemplate(
            input_variables=["history", "input"],
            template=template
        )
        
        # Create chains for each memory type
        for name, memory in self.memory_types.items():
            self.chains[name] = ConversationChain(
                llm=self.llm,
                memory=memory,
                prompt=prompt,
                verbose=False
            )
    
    def chat_with_memory(self, memory_type: str, message: str) -> str:
        """Chat using specific memory type."""
        if memory_type not in self.chains:
            return f"Unknown memory type: {memory_type}"
        
        try:
            response = self.chains[memory_type].predict(input=message)
            return response
        except Exception as e:
            return f"Error: {str(e)}"
    
    def get_memory_info(self, memory_type: str) -> Dict[str, Any]:
        """Get information about the memory state."""
        if memory_type not in self.memory_types:
            return {"error": f"Unknown memory type: {memory_type}"}
        
        memory = self.memory_types[memory_type]
        
        try:
            info = {
                "type": memory_type,
                "class": memory.__class__.__name__
            }
            
            # Get memory buffer if available
            if hasattr(memory, 'buffer'):
                info["buffer"] = str(memory.buffer)
            
            # Get chat memory if available
            if hasattr(memory, 'chat_memory'):
                info["message_count"] = len(memory.chat_memory.messages)
                info["messages"] = [
                    {"type": msg.__class__.__name__, "content": msg.content}
                    for msg in memory.chat_memory.messages
                ]
            
            # Get summary if available
            if hasattr(memory, 'summary') and memory.summary:
                info["summary"] = memory.summary
            
            return info
            
        except Exception as e:
            return {"error": f"Error getting memory info: {str(e)}"}
    
    def clear_memory(self, memory_type: str):
        """Clear specific memory type."""
        if memory_type in self.memory_types:
            self.memory_types[memory_type].clear()
            print(f"🧹 {memory_type} memory cleared")
    
    def clear_all_memory(self):
        """Clear all memory types."""
        for memory_type in self.memory_types:
            self.memory_types[memory_type].clear()
        print("🧹 All memory cleared")
    
    def get_available_memory_types(self) -> List[str]:
        """Get list of available memory types."""
        return list(self.memory_types.keys())
    
    def memory_comparison_demo(self):
        """Demonstrate differences between memory types."""
        print("🔄 Memory Comparison Demo")
        print("=" * 50)
        
        # Test conversations
        test_messages = [
            "My name is Alice and I'm a software engineer.",
            "I work at a tech company in San Francisco.",
            "I love Python programming and machine learning.",
            "What do you remember about me?"
        ]
        
        for memory_type in self.memory_types.keys():
            print(f"\n📝 Testing {memory_type} memory:")
            print("-" * 30)
            
            for i, message in enumerate(test_messages):
                print(f"Human: {message}")
                response = self.chat_with_memory(memory_type, message)
                print(f"AI: {response}")
                
                if i == len(test_messages) - 1:  # Last message
                    # Show memory info
                    memory_info = self.get_memory_info(memory_type)
                    print(f"\n🧠 Memory Info for {memory_type}:")
                    if "error" in memory_info:
                        print(f"  Error: {memory_info['error']}")
                    else:
                        print(f"  Type: {memory_info['class']}")
                        if "message_count" in memory_info:
                            print(f"  Messages: {memory_info['message_count']}")
                        if "summary" in memory_info:
                            print(f"  Summary: {memory_info['summary']}")
            
            # Clear memory for next test
            self.clear_memory(memory_type)
            print()

def main():
    """Main function demonstrating LangChain memory."""
    print("🧠 LangChain Memory Example")
    print("=" * 50)
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable is not set")
        print("Please set your OpenAI API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize memory demo
        memory_demo = MemoryDemo()
        memory_types = memory_demo.get_available_memory_types()
        
        print(f"✅ Memory demo initialized with types: {', '.join(memory_types)}")
        print("\nMemory Types:")
        print("- buffer: Keeps all conversation history")
        print("- buffer_window: Keeps last K exchanges")
        print("- summary: Summarizes old conversations")
        print("- summary_buffer: Combines summary and recent messages")
        print("-" * 50)
        
        # Interactive mode
        print("🤖 Interactive Memory Demo")
        print("Commands:")
        print("  'demo' - Run automatic comparison demo")
        print("  'use <type>' - Switch memory type")
        print("  'info <type>' - Show memory info")
        print("  'clear <type>' - Clear specific memory")
        print("  'clear all' - Clear all memory")
        print("  'types' - Show available memory types")
        print("  'quit' - Exit")
        print("-" * 50)
        
        current_memory = "buffer"
        print(f"Current memory type: {current_memory}")
        
        while True:
            # Get user input
            user_input = input("\n🧑 You: ").strip()
            
            # Handle special commands
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'demo':
                memory_demo.memory_comparison_demo()
                continue
            elif user_input.lower().startswith('use '):
                new_type = user_input[4:]
                if new_type in memory_types:
                    current_memory = new_type
                    print(f"✅ Switched to {current_memory} memory")
                else:
                    print(f"❌ Unknown memory type: {new_type}")
                continue
            elif user_input.lower().startswith('info '):
                info_type = user_input[5:]
                if info_type in memory_types:
                    info = memory_demo.get_memory_info(info_type)
                    print(f"🧠 Memory Info for {info_type}:")
                    for key, value in info.items():
                        if key == "messages":
                            print(f"  {key}: {len(value)} messages")
                        else:
                            print(f"  {key}: {value}")
                else:
                    print(f"❌ Unknown memory type: {info_type}")
                continue
            elif user_input.lower().startswith('clear '):
                clear_type = user_input[6:]
                if clear_type == "all":
                    memory_demo.clear_all_memory()
                elif clear_type in memory_types:
                    memory_demo.clear_memory(clear_type)
                else:
                    print(f"❌ Unknown memory type: {clear_type}")
                continue
            elif user_input.lower() == 'types':
                print(f"Available memory types: {', '.join(memory_types)}")
                continue
            elif not user_input:
                continue
            
            # Chat with current memory type
            print(f"🤖 AI ({current_memory}): ", end="", flush=True)
            response = memory_demo.chat_with_memory(current_memory, user_input)
            print(response)
            
    except KeyboardInterrupt:
        print("\n\n👋 Memory demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()