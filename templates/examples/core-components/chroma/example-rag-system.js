/**
 * Chroma RAG (Retrieval-Augmented Generation) System Example
 * 
 * This example demonstrates:
 * - RAG system implementation
 * - Context retrieval from vector database
 * - LLM integration patterns
 * - Response generation with retrieved context
 * - Knowledge base management
 * 
 * Usage:
 * npm install chromadb openai
 * node example-rag-system.js
 */

const { ChromaClient } = require('chromadb');
const { OpenAI } = require('openai');

// ==========================================
// RAG SYSTEM IMPLEMENTATION
// ==========================================

class RAGSystem {
    constructor(options = {}) {
        this.chromaClient = new ChromaClient({
            path: options.chromaUrl || 'http://localhost:8000'
        });
        
        this.openai = new OpenAI({
            apiKey: options.openaiApiKey || process.env.OPENAI_API_KEY
        });
        
        this.embeddingModel = options.embeddingModel || 'text-embedding-3-small';
        this.chatModel = options.chatModel || 'gpt-3.5-turbo';
        this.collection = null;
        this.knowledgeBase = [];
    }

    /**
     * Initialize the RAG system
     */
    async initialize(collectionName = 'rag_knowledge_base') {
        try {
            this.collection = await this.chromaClient.getOrCreateCollection({
                name: collectionName,
                metadata: {
                    description: 'Knowledge base for RAG system',
                    created_at: new Date().toISOString()
                }
            });
            
            console.log(`✅ RAG system initialized with collection: ${collectionName}`);
            return true;
        } catch (error) {
            console.error('❌ Error initializing RAG system:', error);
            return false;
        }
    }

    /**
     * Generate embeddings for text
     */
    async generateEmbeddings(texts) {
        try {
            const response = await this.openai.embeddings.create({
                model: this.embeddingModel,
                input: texts
            });
            
            return response.data.map(item => item.embedding);
        } catch (error) {
            console.error('❌ Error generating embeddings:', error);
            
            // Fallback to random embeddings for demo purposes
            console.log('⚠️ Using random embeddings for demo');
            return texts.map(() => this.generateRandomEmbedding());
        }
    }

    /**
     * Generate random embedding (fallback)
     */
    generateRandomEmbedding(dimension = 1536) {
        return Array.from({ length: dimension }, () => Math.random() * 2 - 1);
    }

    /**
     * Add documents to the knowledge base
     */
    async addDocuments(documents) {
        try {
            const texts = documents.map(doc => doc.text);
            const embeddings = await this.generateEmbeddings(texts);
            
            const ids = documents.map((_, index) => `doc_${Date.now()}_${index}`);
            const metadatas = documents.map(doc => ({
                source: doc.source || 'unknown',
                category: doc.category || 'general',
                created_at: new Date().toISOString(),
                ...doc.metadata
            }));
            
            await this.collection.add({
                ids,
                embeddings,
                metadatas,
                documents: texts
            });
            
            console.log(`✅ Added ${documents.length} documents to knowledge base`);
            return { success: true, count: documents.length, ids };
        } catch (error) {
            console.error('❌ Error adding documents:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Retrieve relevant documents based on query
     */
    async retrieveContext(query, options = {}) {
        try {
            const {
                topK = 5,
                threshold = 0.7,
                includeMetadata = true,
                filters = {}
            } = options;
            
            // Generate embedding for the query
            const queryEmbedding = await this.generateEmbeddings([query]);
            
            // Search for similar documents
            const results = await this.collection.query({
                queryEmbeddings: queryEmbedding,
                nResults: topK,
                where: Object.keys(filters).length > 0 ? filters : undefined,
                include: ['metadatas', 'documents', 'distances']
            });
            
            // Filter by distance threshold
            const relevantDocs = [];
            if (results.ids[0]) {
                for (let i = 0; i < results.ids[0].length; i++) {
                    const distance = results.distances[0][i];
                    const similarity = 1 - distance; // Convert distance to similarity
                    
                    if (similarity >= threshold) {
                        relevantDocs.push({
                            id: results.ids[0][i],
                            text: results.documents[0][i],
                            metadata: results.metadatas[0][i],
                            similarity: similarity.toFixed(3),
                            distance: distance.toFixed(3)
                        });
                    }
                }
            }
            
            console.log(`🔍 Retrieved ${relevantDocs.length} relevant documents (threshold: ${threshold})`);
            return relevantDocs;
        } catch (error) {
            console.error('❌ Error retrieving context:', error);
            return [];
        }
    }

    /**
     * Generate response using retrieved context
     */
    async generateResponse(query, context, options = {}) {
        try {
            const {
                maxTokens = 500,
                temperature = 0.7,
                systemPrompt = 'You are a helpful assistant that answers questions based on the provided context.'
            } = options;
            
            // Prepare context string
            const contextString = context
                .map((doc, index) => `[${index + 1}] ${doc.text}`)
                .join('\\n\\n');
            
            // Create the prompt
            const prompt = `Context information:
${contextString}

Question: ${query}

Based on the context provided above, please provide a comprehensive answer to the question. If the context doesn't contain relevant information, please state that clearly.`;
            
            // Generate response using OpenAI
            const response = await this.openai.chat.completions.create({
                model: this.chatModel,
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: prompt }
                ],
                max_tokens: maxTokens,
                temperature: temperature
            });
            
            const answer = response.choices[0].message.content;
            
            return {
                answer,
                context: context.map(doc => ({
                    id: doc.id,
                    text: doc.text.substring(0, 200) + '...',
                    source: doc.metadata.source,
                    similarity: doc.similarity
                })),
                usage: response.usage
            };
        } catch (error) {
            console.error('❌ Error generating response:', error);
            
            // Fallback response
            return {
                answer: 'I apologize, but I encountered an error while generating a response. Please try again.',
                context: context,
                error: error.message
            };
        }
    }

    /**
     * Complete RAG pipeline: retrieve + generate
     */
    async query(question, options = {}) {
        try {
            console.log(`❓ Processing question: "${question}"`);
            
            // Retrieve relevant context
            const context = await this.retrieveContext(question, options);
            
            if (context.length === 0) {
                return {
                    answer: 'I could not find relevant information in the knowledge base to answer your question.',
                    context: [],
                    sources: []
                };
            }
            
            // Generate response
            const response = await this.generateResponse(question, context, options);
            
            console.log(`✅ Generated response with ${context.length} context documents`);
            return response;
        } catch (error) {
            console.error('❌ Error in RAG query:', error);
            return {
                answer: 'An error occurred while processing your question.',
                context: [],
                error: error.message
            };
        }
    }

    /**
     * Batch process multiple questions
     */
    async batchQuery(questions, options = {}) {
        const results = [];
        
        for (const question of questions) {
            console.log(`\\n--- Processing: ${question} ---`);
            const result = await this.query(question, options);
            results.push({
                question,
                ...result
            });
        }
        
        return results;
    }

    /**
     * Update knowledge base with new documents
     */
    async updateKnowledgeBase(documents) {
        return await this.addDocuments(documents);
    }

    /**
     * Search knowledge base
     */
    async searchKnowledgeBase(query, options = {}) {
        const context = await this.retrieveContext(query, options);
        return context;
    }

    /**
     * Get knowledge base statistics
     */
    async getKnowledgeBaseStats() {
        try {
            const count = await this.collection.count();
            
            // Get sample documents to analyze
            const sample = await this.collection.get({
                limit: 10,
                include: ['metadatas']
            });
            
            // Analyze sources and categories
            const sources = new Set();
            const categories = new Set();
            
            sample.metadatas.forEach(metadata => {
                if (metadata.source) sources.add(metadata.source);
                if (metadata.category) categories.add(metadata.category);
            });
            
            const stats = {
                totalDocuments: count,
                sources: Array.from(sources),
                categories: Array.from(categories),
                sampleCount: sample.ids.length
            };
            
            console.log('📊 Knowledge base statistics:', stats);
            return stats;
        } catch (error) {
            console.error('❌ Error getting knowledge base stats:', error);
            return null;
        }
    }
}

// ==========================================
// KNOWLEDGE BASE LOADER
// ==========================================

class KnowledgeBaseLoader {
    constructor(ragSystem) {
        this.ragSystem = ragSystem;
    }

    /**
     * Load sample technology documents
     */
    async loadTechnologyDocs() {
        const docs = [
            {
                text: "React is a JavaScript library for building user interfaces. It allows developers to create reusable UI components and manage application state efficiently. React uses a virtual DOM to optimize rendering performance.",
                source: "React Documentation",
                category: "web-development"
            },
            {
                text: "Python is a high-level programming language known for its simplicity and readability. It's widely used in data science, machine learning, web development, and automation. Python has a rich ecosystem of libraries and frameworks.",
                source: "Python Guide",
                category: "programming"
            },
            {
                text: "Docker is a containerization platform that allows developers to package applications and their dependencies into lightweight, portable containers. It ensures consistency across different environments and simplifies deployment.",
                source: "Docker Documentation",
                category: "devops"
            },
            {
                text: "Machine learning is a subset of artificial intelligence that enables computers to learn and make decisions from data without being explicitly programmed. It includes supervised, unsupervised, and reinforcement learning approaches.",
                source: "ML Textbook",
                category: "machine-learning"
            },
            {
                text: "PostgreSQL is a powerful, open-source relational database management system. It supports advanced SQL features, JSON data types, and provides excellent performance for complex queries and transactions.",
                source: "PostgreSQL Manual",
                category: "database"
            },
            {
                text: "Redis is an in-memory data structure store used as a database, cache, and message broker. It supports various data types like strings, hashes, lists, sets, and sorted sets, making it ideal for high-performance applications.",
                source: "Redis Documentation",
                category: "database"
            },
            {
                text: "Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. It provides features like service discovery, load balancing, and self-healing.",
                source: "Kubernetes Guide",
                category: "devops"
            },
            {
                text: "FastAPI is a modern, fast web framework for building APIs with Python. It provides automatic API documentation, built-in validation, and supports asynchronous programming for high-performance applications.",
                source: "FastAPI Documentation",
                category: "web-development"
            }
        ];
        
        return await this.ragSystem.addDocuments(docs);
    }

    /**
     * Load documents from text file
     */
    async loadFromText(text, options = {}) {
        const {
            chunkSize = 500,
            overlap = 50,
            source = 'text-file',
            category = 'general'
        } = options;
        
        // Split text into chunks
        const chunks = this.splitTextIntoChunks(text, chunkSize, overlap);
        
        const docs = chunks.map((chunk, index) => ({
            text: chunk,
            source: source,
            category: category,
            metadata: {
                chunk_index: index,
                chunk_size: chunk.length
            }
        }));
        
        return await this.ragSystem.addDocuments(docs);
    }

    /**
     * Split text into overlapping chunks
     */
    splitTextIntoChunks(text, chunkSize, overlap) {
        const chunks = [];
        let start = 0;
        
        while (start < text.length) {
            const end = Math.min(start + chunkSize, text.length);
            chunks.push(text.substring(start, end));
            start = end - overlap;
        }
        
        return chunks;
    }
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runRAGSystemExample() {
    try {
        console.log('=== RAG System Example ===');
        
        // Initialize RAG system
        const ragSystem = new RAGSystem({
            chromaUrl: 'http://localhost:8000',
            embeddingModel: 'text-embedding-3-small',
            chatModel: 'gpt-3.5-turbo'
        });
        
        const initialized = await ragSystem.initialize('tech_knowledge_base');
        if (!initialized) {
            console.log('❌ Failed to initialize RAG system');
            return;
        }
        
        // Load knowledge base
        const loader = new KnowledgeBaseLoader(ragSystem);
        console.log('\\n=== Loading Knowledge Base ===');
        const loadResult = await loader.loadTechnologyDocs();
        console.log('Load result:', loadResult);
        
        // Get knowledge base statistics
        await ragSystem.getKnowledgeBaseStats();
        
        console.log('\\n=== RAG Query Examples ===');
        
        // Example queries
        const questions = [
            'What is React and how does it work?',
            'How do you use Docker for deployment?',
            'What are the benefits of PostgreSQL?',
            'Explain machine learning approaches',
            'What is Kubernetes used for?'
        ];
        
        // Process each question
        for (const question of questions) {
            console.log(`\\n--- Question: ${question} ---`);
            
            const result = await ragSystem.query(question, {
                topK: 3,
                threshold: 0.1, // Lower threshold for demo
                maxTokens: 300,
                temperature: 0.7
            });
            
            console.log('\\n🤖 Answer:', result.answer);
            console.log('\\n📚 Sources used:');
            result.context.forEach((doc, index) => {
                console.log(`  ${index + 1}. ${doc.source} (similarity: ${doc.similarity})`);
                console.log(`     "${doc.text}"`);
            });
            
            if (result.usage) {
                console.log('\\n📊 Usage:', result.usage);
            }
        }
        
        console.log('\\n=== Search Knowledge Base ===');
        
        // Search without generating response
        const searchResults = await ragSystem.searchKnowledgeBase('web development frameworks', {
            topK: 3,
            threshold: 0.2
        });
        
        console.log('🔍 Search results:');
        searchResults.forEach((doc, index) => {
            console.log(`  ${index + 1}. ${doc.metadata.source} (similarity: ${doc.similarity})`);
            console.log(`     Category: ${doc.metadata.category}`);
            console.log(`     "${doc.text.substring(0, 100)}..."`);
        });
        
        console.log('\\n=== Batch Query Example ===');
        
        const batchQuestions = [
            'What programming languages are mentioned?',
            'Which databases are discussed?'
        ];
        
        const batchResults = await ragSystem.batchQuery(batchQuestions, {
            topK: 2,
            threshold: 0.2,
            maxTokens: 200
        });
        
        batchResults.forEach((result, index) => {
            console.log(`\\n${index + 1}. ${result.question}`);
            console.log(`   Answer: ${result.answer}`);
            console.log(`   Sources: ${result.context.length}`);
        });
        
        console.log('\\n=== Final Statistics ===');
        await ragSystem.getKnowledgeBaseStats();
        
    } catch (error) {
        console.error('Error in RAG system example:', error);
    }
}

// ==========================================
// CONVERSATIONAL RAG
// ==========================================

class ConversationalRAG extends RAGSystem {
    constructor(options = {}) {
        super(options);
        this.conversationHistory = [];
        this.maxHistoryLength = options.maxHistoryLength || 10;
    }

    /**
     * Add conversation turn to history
     */
    addToHistory(question, answer, context) {
        this.conversationHistory.push({
            question,
            answer,
            context: context.map(doc => doc.id),
            timestamp: new Date().toISOString()
        });
        
        // Keep only recent history
        if (this.conversationHistory.length > this.maxHistoryLength) {
            this.conversationHistory.shift();
        }
    }

    /**
     * Query with conversation context
     */
    async conversationalQuery(question, options = {}) {
        // Include conversation history in the query
        const historyContext = this.conversationHistory
            .slice(-3) // Last 3 turns
            .map(turn => `Q: ${turn.question}\\nA: ${turn.answer}`)
            .join('\\n\\n');
        
        const contextualQuestion = historyContext 
            ? `Previous conversation:\\n${historyContext}\\n\\nCurrent question: ${question}`
            : question;
        
        const result = await this.query(contextualQuestion, options);
        
        // Add to history
        this.addToHistory(question, result.answer, result.context);
        
        return result;
    }

    /**
     * Get conversation history
     */
    getConversationHistory() {
        return this.conversationHistory;
    }

    /**
     * Clear conversation history
     */
    clearHistory() {
        this.conversationHistory = [];
    }
}

// Run example when script is executed directly
if (require.main === module) {
    runRAGSystemExample().catch(console.error);
}

module.exports = {
    RAGSystem,
    KnowledgeBaseLoader,
    ConversationalRAG
};