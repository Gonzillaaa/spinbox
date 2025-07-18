#!/usr/bin/env node
/**
 * Anthropic Claude Chat Example (JavaScript/Node.js)
 * 
 * This example demonstrates how to integrate Anthropic's Claude API
 * for basic chat functionality with proper error handling and configuration.
 */

import Anthropic from '@anthropic-ai/sdk';
import dotenv from 'dotenv';
import readline from 'readline';
import process from 'process';

// Load environment variables
dotenv.config();

class ClaudeChat {
    /**
     * Simple Claude chat client with conversation history.
     */
    constructor(apiKey = null) {
        this.apiKey = apiKey || process.env.ANTHROPIC_API_KEY;
        if (!this.apiKey) {
            throw new Error('ANTHROPIC_API_KEY is required');
        }

        this.client = new Anthropic({ apiKey: this.apiKey });
        this.conversationHistory = [];
        
        // Configuration from environment variables
        this.model = process.env.ANTHROPIC_MODEL || 'claude-3-sonnet-20240229';
        this.maxTokens = parseInt(process.env.ANTHROPIC_MAX_TOKENS || '1024');
        this.temperature = parseFloat(process.env.ANTHROPIC_TEMPERATURE || '0.7');
    }

    /**
     * Send a message to Claude and get response.
     */
    async chat(message) {
        try {
            // Add user message to conversation history
            this.conversationHistory.push({ role: 'user', content: message });
            
            // Create the API request
            const response = await this.client.messages.create({
                model: this.model,
                max_tokens: this.maxTokens,
                temperature: this.temperature,
                messages: this.conversationHistory
            });
            
            // Extract the response text
            const responseText = response.content[0].text;
            
            // Add assistant response to conversation history
            this.conversationHistory.push({ role: 'assistant', content: responseText });
            
            return responseText;
            
        } catch (error) {
            const errorMsg = `Error communicating with Claude: ${error.message}`;
            console.error(`🚨 ${errorMsg}`);
            return errorMsg;
        }
    }

    /**
     * Clear the conversation history.
     */
    clearHistory() {
        this.conversationHistory = [];
        console.log('🧹 Conversation history cleared');
    }

    /**
     * Get a summary of the current conversation.
     */
    getConversationSummary() {
        return {
            totalMessages: this.conversationHistory.length,
            userMessages: this.conversationHistory.filter(m => m.role === 'user').length,
            assistantMessages: this.conversationHistory.filter(m => m.role === 'assistant').length,
            model: this.model,
            maxTokens: this.maxTokens,
            temperature: this.temperature
        };
    }
}

/**
 * Main function demonstrating Claude chat functionality.
 */
async function main() {
    console.log('🤖 Anthropic Claude Chat Example (JavaScript)');
    console.log('='.repeat(50));
    
    // Check for API key
    if (!process.env.ANTHROPIC_API_KEY) {
        console.error('❌ Error: ANTHROPIC_API_KEY environment variable is not set');
        console.error('Please set your Anthropic API key in the .env file');
        process.exit(1);
    }
    
    try {
        // Initialize the chat client
        const chatClient = new ClaudeChat();
        console.log(`✅ Connected to Claude (${chatClient.model})`);
        console.log("Type 'quit' to exit, 'clear' to clear history, 'summary' for conversation summary");
        console.log('-'.repeat(50));
        
        // Create readline interface
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        // Main chat loop
        const askQuestion = () => {
            rl.question('\n🧑 You: ', async (userInput) => {
                const input = userInput.trim();
                
                // Handle special commands
                if (input.toLowerCase() === 'quit') {
                    console.log('👋 Goodbye!');
                    rl.close();
                    return;
                } else if (input.toLowerCase() === 'clear') {
                    chatClient.clearHistory();
                    askQuestion();
                    return;
                } else if (input.toLowerCase() === 'summary') {
                    const summary = chatClient.getConversationSummary();
                    console.log('\n📊 Conversation Summary:');
                    Object.entries(summary).forEach(([key, value]) => {
                        console.log(`   ${key}: ${value}`);
                    });
                    askQuestion();
                    return;
                } else if (!input) {
                    askQuestion();
                    return;
                }
                
                // Send message to Claude
                process.stdout.write('🤖 Claude: ');
                const response = await chatClient.chat(input);
                console.log(response);
                
                // Continue the conversation
                askQuestion();
            });
        };
        
        // Start the conversation
        askQuestion();
        
    } catch (error) {
        console.error(`\n❌ Unexpected error: ${error.message}`);
        process.exit(1);
    }
}

// Handle process interruption
process.on('SIGINT', () => {
    console.log('\n\n👋 Chat interrupted by user');
    process.exit(0);
});

// Run the main function
if (import.meta.url === `file://${process.argv[1]}`) {
    main();
}