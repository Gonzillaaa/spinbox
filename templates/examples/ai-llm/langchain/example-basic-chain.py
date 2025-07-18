#!/usr/bin/env python3
"""
LangChain Basic Chain Example

This example demonstrates basic LangChain usage with prompt templates,
chains, and different LLM providers.
"""

import os
import sys
from typing import Dict, Any, Optional
from langchain.llms import OpenAI
from langchain.chat_models import ChatOpenAI, ChatAnthropic
from langchain.prompts import PromptTemplate, ChatPromptTemplate
from langchain.chains import LLMChain
from langchain.schema import HumanMessage, AIMessage, SystemMessage
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class LangChainBasics:
    """Basic LangChain functionality demonstration."""
    
    def __init__(self):
        """Initialize LangChain components."""
        # Check for API keys
        self.openai_key = os.getenv("OPENAI_API_KEY")
        self.anthropic_key = os.getenv("ANTHROPIC_API_KEY")
        
        if not self.openai_key and not self.anthropic_key:
            raise ValueError("Either OPENAI_API_KEY or ANTHROPIC_API_KEY is required")
        
        # Configuration
        self.temperature = float(os.getenv("LANGCHAIN_TEMPERATURE", "0.7"))
        self.max_tokens = int(os.getenv("LANGCHAIN_MAX_TOKENS", "1024"))
        self.verbose = os.getenv("LANGCHAIN_VERBOSE", "false").lower() == "true"
        
        # Initialize LLMs
        self.llms = {}
        if self.openai_key:
            self.llms["openai"] = ChatOpenAI(
                api_key=self.openai_key,
                model_name="gpt-3.5-turbo",
                temperature=self.temperature,
                max_tokens=self.max_tokens
            )
        
        if self.anthropic_key:
            self.llms["anthropic"] = ChatAnthropic(
                api_key=self.anthropic_key,
                model="claude-3-sonnet-20240229",
                temperature=self.temperature,
                max_tokens=self.max_tokens
            )
    
    def simple_prompt_example(self, provider: str = "openai") -> str:
        """Demonstrate simple prompt usage."""
        if provider not in self.llms:
            return f"Provider {provider} not available"
        
        try:
            llm = self.llms[provider]
            
            # Simple prompt template
            template = """
            You are a helpful assistant. Answer the following question clearly and concisely.
            
            Question: {question}
            Answer:
            """
            
            prompt = PromptTemplate(
                input_variables=["question"],
                template=template
            )
            
            # Create chain
            chain = LLMChain(llm=llm, prompt=prompt, verbose=self.verbose)
            
            # Run the chain
            result = chain.run(question="What is artificial intelligence?")
            
            return result
            
        except Exception as e:
            return f"Error with {provider}: {str(e)}"
    
    def chat_prompt_example(self, provider: str = "openai") -> str:
        """Demonstrate chat prompt templates."""
        if provider not in self.llms:
            return f"Provider {provider} not available"
        
        try:
            llm = self.llms[provider]
            
            # Chat prompt template
            chat_prompt = ChatPromptTemplate.from_messages([
                SystemMessage(content="You are a creative writing assistant."),
                HumanMessage(content="Write a short story about {topic} in {style} style.")
            ])
            
            # Create chain
            chain = LLMChain(llm=llm, prompt=chat_prompt, verbose=self.verbose)
            
            # Run the chain
            result = chain.run(topic="robots", style="cyberpunk")
            
            return result
            
        except Exception as e:
            return f"Error with {provider}: {str(e)}"
    
    def multi_step_chain_example(self, provider: str = "openai") -> Dict[str, Any]:
        """Demonstrate multi-step chain processing."""
        if provider not in self.llms:
            return {"error": f"Provider {provider} not available"}
        
        try:
            llm = self.llms[provider]
            
            # Step 1: Generate ideas
            idea_template = """
            Generate 3 creative business ideas for a {industry} company.
            Focus on innovative solutions and market opportunities.
            
            Industry: {industry}
            Ideas:
            """
            
            idea_prompt = PromptTemplate(
                input_variables=["industry"],
                template=idea_template
            )
            
            idea_chain = LLMChain(llm=llm, prompt=idea_prompt, verbose=self.verbose)
            
            # Step 2: Analyze the best idea
            analysis_template = """
            Analyze the following business ideas and select the most promising one.
            Provide a detailed analysis including market potential, challenges, and next steps.
            
            Business Ideas:
            {ideas}
            
            Analysis:
            """
            
            analysis_prompt = PromptTemplate(
                input_variables=["ideas"],
                template=analysis_template
            )
            
            analysis_chain = LLMChain(llm=llm, prompt=analysis_prompt, verbose=self.verbose)
            
            # Execute the multi-step process
            industry = "sustainable technology"
            ideas = idea_chain.run(industry=industry)
            analysis = analysis_chain.run(ideas=ideas)
            
            return {
                "industry": industry,
                "ideas": ideas,
                "analysis": analysis
            }
            
        except Exception as e:
            return {"error": f"Error with {provider}: {str(e)}"}
    
    def custom_output_parser_example(self, provider: str = "openai") -> Dict[str, Any]:
        """Demonstrate custom output parsing."""
        if provider not in self.llms:
            return {"error": f"Provider {provider} not available"}
        
        try:
            llm = self.llms[provider]
            
            # Template with structured output
            template = """
            Analyze the following product and provide a structured response.
            
            Product: {product}
            
            Please provide your analysis in the following format:
            PROS: [list the advantages]
            CONS: [list the disadvantages]
            RATING: [give a rating from 1-10]
            RECOMMENDATION: [provide a recommendation]
            """
            
            prompt = PromptTemplate(
                input_variables=["product"],
                template=template
            )
            
            chain = LLMChain(llm=llm, prompt=prompt, verbose=self.verbose)
            
            # Run the chain
            result = chain.run(product="electric vehicle")
            
            # Simple parsing (in a real app, you'd use a proper parser)
            parsed = self._parse_structured_response(result)
            
            return {
                "raw_response": result,
                "parsed_response": parsed
            }
            
        except Exception as e:
            return {"error": f"Error with {provider}: {str(e)}"}
    
    def _parse_structured_response(self, response: str) -> Dict[str, str]:
        """Simple parser for structured responses."""
        parsed = {}
        lines = response.strip().split('\n')
        
        for line in lines:
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip().lower()
                value = value.strip()
                parsed[key] = value
        
        return parsed
    
    def get_available_providers(self) -> list:
        """Get list of available providers."""
        return list(self.llms.keys())

def main():
    """Main function demonstrating LangChain basics."""
    print("🔗 LangChain Basic Chain Example")
    print("=" * 50)
    
    # Check for API keys
    if not os.getenv("OPENAI_API_KEY") and not os.getenv("ANTHROPIC_API_KEY"):
        print("❌ Error: Either OPENAI_API_KEY or ANTHROPIC_API_KEY environment variable is required")
        print("Please set at least one API key in the .env file")
        sys.exit(1)
    
    try:
        # Initialize LangChain
        lc = LangChainBasics()
        providers = lc.get_available_providers()
        
        print(f"✅ LangChain initialized with providers: {', '.join(providers)}")
        print(f"Using temperature: {lc.temperature}, max_tokens: {lc.max_tokens}")
        print("-" * 50)
        
        # Use the first available provider
        provider = providers[0]
        print(f"Using provider: {provider}")
        
        # Example 1: Simple prompt
        print("\n1. Simple Prompt Example")
        print("-" * 30)
        result = lc.simple_prompt_example(provider)
        print(f"Result: {result}")
        
        # Example 2: Chat prompt
        print("\n2. Chat Prompt Example")
        print("-" * 30)
        result = lc.chat_prompt_example(provider)
        print(f"Result: {result}")
        
        # Example 3: Multi-step chain
        print("\n3. Multi-step Chain Example")
        print("-" * 30)
        result = lc.multi_step_chain_example(provider)
        if "error" in result:
            print(f"Error: {result['error']}")
        else:
            print(f"Industry: {result['industry']}")
            print(f"Ideas: {result['ideas']}")
            print(f"Analysis: {result['analysis']}")
        
        # Example 4: Custom output parser
        print("\n4. Custom Output Parser Example")
        print("-" * 30)
        result = lc.custom_output_parser_example(provider)
        if "error" in result:
            print(f"Error: {result['error']}")
        else:
            print(f"Raw Response: {result['raw_response']}")
            print(f"Parsed Response: {result['parsed_response']}")
        
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()