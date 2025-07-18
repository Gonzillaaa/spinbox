/**
 * Chroma Basic Operations Examples
 * 
 * This example demonstrates:
 * - Collection creation and management
 * - Document insertion and retrieval
 * - Basic vector operations
 * - Error handling
 * - Connection management
 * 
 * Usage:
 * npm install chromadb
 * node example-basic-operations.js
 */

const { ChromaClient } = require('chromadb');

// ==========================================
// CHROMA CLIENT SETUP
// ==========================================

class ChromaManager {
    constructor(host = 'localhost', port = 8000) {
        this.client = new ChromaClient({
            path: `http://${host}:${port}`,
            auth: process.env.CHROMA_AUTH_TOKEN ? {
                provider: "token",
                credentials: process.env.CHROMA_AUTH_TOKEN
            } : undefined
        });
        this.collections = new Map();
    }

    /**
     * Test connection to Chroma
     */
    async testConnection() {
        try {
            const heartbeat = await this.client.heartbeat();
            console.log('✅ Connected to Chroma:', heartbeat);
            return true;
        } catch (error) {
            console.error('❌ Chroma connection failed:', error);
            return false;
        }
    }

    /**
     * Get client version
     */
    async getVersion() {
        try {
            const version = await this.client.version();
            console.log('📊 Chroma version:', version);
            return version;
        } catch (error) {
            console.error('❌ Error getting version:', error);
            return null;
        }
    }

    /**
     * List all collections
     */
    async listCollections() {
        try {
            const collections = await this.client.listCollections();
            console.log('📚 Available collections:', collections.map(c => c.name));
            return collections;
        } catch (error) {
            console.error('❌ Error listing collections:', error);
            return [];
        }
    }

    /**
     * Create a collection
     */
    async createCollection(name, metadata = {}) {
        try {
            const collection = await this.client.createCollection({
                name,
                metadata: {
                    description: `Collection for ${name}`,
                    created_at: new Date().toISOString(),
                    ...metadata
                }
            });
            
            this.collections.set(name, collection);
            console.log(`✅ Created collection: ${name}`);
            return collection;
        } catch (error) {
            console.error(`❌ Error creating collection ${name}:`, error);
            throw error;
        }
    }

    /**
     * Get or create collection
     */
    async getOrCreateCollection(name, metadata = {}) {
        try {
            const collection = await this.client.getOrCreateCollection({
                name,
                metadata: {
                    description: `Collection for ${name}`,
                    created_at: new Date().toISOString(),
                    ...metadata
                }
            });
            
            this.collections.set(name, collection);
            console.log(`✅ Got/Created collection: ${name}`);
            return collection;
        } catch (error) {
            console.error(`❌ Error getting/creating collection ${name}:`, error);
            throw error;
        }
    }

    /**
     * Delete a collection
     */
    async deleteCollection(name) {
        try {
            await this.client.deleteCollection({ name });
            this.collections.delete(name);
            console.log(`✅ Deleted collection: ${name}`);
            return true;
        } catch (error) {
            console.error(`❌ Error deleting collection ${name}:`, error);
            return false;
        }
    }

    /**
     * Get collection
     */
    async getCollection(name) {
        try {
            if (this.collections.has(name)) {
                return this.collections.get(name);
            }
            
            const collection = await this.client.getCollection({ name });
            this.collections.set(name, collection);
            return collection;
        } catch (error) {
            console.error(`❌ Error getting collection ${name}:`, error);
            throw error;
        }
    }
}

// ==========================================
// DOCUMENT OPERATIONS
// ==========================================

class DocumentManager {
    constructor(chromaManager) {
        this.chromaManager = chromaManager;
    }

    /**
     * Add documents to collection
     */
    async addDocuments(collectionName, documents) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            
            const ids = documents.map((_, index) => `doc_${Date.now()}_${index}`);
            const embeddings = documents.map(doc => doc.embedding);
            const metadatas = documents.map(doc => doc.metadata || {});
            const documentsText = documents.map(doc => doc.text);

            await collection.add({
                ids,
                embeddings,
                metadatas,
                documents: documentsText
            });

            console.log(`✅ Added ${documents.length} documents to ${collectionName}`);
            return { success: true, ids };
        } catch (error) {
            console.error('❌ Error adding documents:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Update documents in collection
     */
    async updateDocuments(collectionName, updates) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            
            const ids = updates.map(update => update.id);
            const embeddings = updates.map(update => update.embedding);
            const metadatas = updates.map(update => update.metadata || {});
            const documents = updates.map(update => update.text);

            await collection.update({
                ids,
                embeddings,
                metadatas,
                documents
            });

            console.log(`✅ Updated ${updates.length} documents in ${collectionName}`);
            return { success: true };
        } catch (error) {
            console.error('❌ Error updating documents:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get documents from collection
     */
    async getDocuments(collectionName, options = {}) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            
            const {
                ids = undefined,
                where = undefined,
                limit = undefined,
                offset = undefined,
                whereDocument = undefined,
                include = ['metadatas', 'documents']
            } = options;

            const result = await collection.get({
                ids,
                where,
                limit,
                offset,
                whereDocument,
                include
            });

            console.log(`✅ Retrieved ${result.ids.length} documents from ${collectionName}`);
            return result;
        } catch (error) {
            console.error('❌ Error getting documents:', error);
            return null;
        }
    }

    /**
     * Delete documents from collection
     */
    async deleteDocuments(collectionName, options = {}) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            
            const {
                ids = undefined,
                where = undefined,
                whereDocument = undefined
            } = options;

            await collection.delete({
                ids,
                where,
                whereDocument
            });

            console.log(`✅ Deleted documents from ${collectionName}`);
            return { success: true };
        } catch (error) {
            console.error('❌ Error deleting documents:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Count documents in collection
     */
    async countDocuments(collectionName) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            const count = await collection.count();
            console.log(`📊 ${collectionName} contains ${count} documents`);
            return count;
        } catch (error) {
            console.error('❌ Error counting documents:', error);
            return 0;
        }
    }

    /**
     * Query documents with vector similarity
     */
    async queryDocuments(collectionName, queryEmbeddings, options = {}) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            
            const {
                nResults = 10,
                where = undefined,
                whereDocument = undefined,
                include = ['metadatas', 'documents', 'distances']
            } = options;

            const results = await collection.query({
                queryEmbeddings,
                nResults,
                where,
                whereDocument,
                include
            });

            console.log(`✅ Query returned ${results.ids[0]?.length || 0} results from ${collectionName}`);
            return results;
        } catch (error) {
            console.error('❌ Error querying documents:', error);
            return null;
        }
    }

    /**
     * Upsert documents (add or update)
     */
    async upsertDocuments(collectionName, documents) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            
            const ids = documents.map(doc => doc.id || `doc_${Date.now()}_${Math.random()}`);
            const embeddings = documents.map(doc => doc.embedding);
            const metadatas = documents.map(doc => doc.metadata || {});
            const documentsText = documents.map(doc => doc.text);

            await collection.upsert({
                ids,
                embeddings,
                metadatas,
                documents: documentsText
            });

            console.log(`✅ Upserted ${documents.length} documents to ${collectionName}`);
            return { success: true, ids };
        } catch (error) {
            console.error('❌ Error upserting documents:', error);
            return { success: false, error: error.message };
        }
    }
}

// ==========================================
// UTILITY FUNCTIONS
// ==========================================

/**
 * Generate random vector for testing
 */
function generateRandomVector(dimension = 384) {
    const vector = [];
    for (let i = 0; i < dimension; i++) {
        vector.push(Math.random() * 2 - 1); // Random number between -1 and 1
    }
    return vector;
}

/**
 * Generate sample documents
 */
function generateSampleDocuments(count = 5) {
    const categories = ['technology', 'science', 'business', 'health', 'entertainment'];
    const documents = [];
    
    for (let i = 0; i < count; i++) {
        const category = categories[i % categories.length];
        documents.push({
            text: `This is a sample document about ${category}. Document number ${i + 1}.`,
            embedding: generateRandomVector(384),
            metadata: {
                category,
                created_at: new Date().toISOString(),
                document_id: i + 1,
                source: 'sample_generator'
            }
        });
    }
    
    return documents;
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

async function runBasicOperationsExamples() {
    const chromaManager = new ChromaManager();
    const documentManager = new DocumentManager(chromaManager);
    
    try {
        console.log('=== Connection Test ===');
        const connected = await chromaManager.testConnection();
        if (!connected) {
            console.log('❌ Cannot connect to Chroma. Please ensure it is running.');
            return;
        }
        
        // Get version
        await chromaManager.getVersion();
        
        console.log('\\n=== Collection Management ===');
        
        // List existing collections
        await chromaManager.listCollections();
        
        // Create a new collection
        const collectionName = 'example_collection';
        await chromaManager.createCollection(collectionName, {
            purpose: 'Example collection for testing basic operations'
        });
        
        // List collections again
        await chromaManager.listCollections();
        
        console.log('\\n=== Document Operations ===');
        
        // Generate sample documents
        const sampleDocs = generateSampleDocuments(5);
        console.log('Generated sample documents:', sampleDocs.length);
        
        // Add documents
        const addResult = await documentManager.addDocuments(collectionName, sampleDocs);
        console.log('Add result:', addResult);
        
        // Count documents
        await documentManager.countDocuments(collectionName);
        
        // Get all documents
        const allDocs = await documentManager.getDocuments(collectionName);
        console.log('All documents:', allDocs.ids.length);
        
        // Get documents with metadata filter
        const filteredDocs = await documentManager.getDocuments(collectionName, {
            where: { category: 'technology' },
            limit: 2
        });
        console.log('Filtered documents:', filteredDocs.ids.length);
        
        console.log('\\n=== Query Operations ===');
        
        // Query with vector similarity
        const queryVector = generateRandomVector(384);
        const queryResults = await documentManager.queryDocuments(
            collectionName,
            [queryVector],
            {
                nResults: 3,
                include: ['metadatas', 'documents', 'distances']
            }
        );
        
        if (queryResults && queryResults.ids[0]) {
            console.log('Query results:');
            for (let i = 0; i < queryResults.ids[0].length; i++) {
                console.log(`  ${i + 1}. ID: ${queryResults.ids[0][i]}`);
                console.log(`     Distance: ${queryResults.distances[0][i]}`);
                console.log(`     Category: ${queryResults.metadatas[0][i].category}`);
                console.log(`     Text: ${queryResults.documents[0][i].substring(0, 50)}...`);
            }
        }
        
        console.log('\\n=== Update Operations ===');
        
        // Update a document
        if (addResult.success && addResult.ids.length > 0) {
            const updateResult = await documentManager.updateDocuments(collectionName, [{
                id: addResult.ids[0],
                text: 'This is an updated document about technology.',
                embedding: generateRandomVector(384),
                metadata: {
                    category: 'technology',
                    updated_at: new Date().toISOString(),
                    status: 'updated'
                }
            }]);
            console.log('Update result:', updateResult);
        }
        
        console.log('\\n=== Upsert Operations ===');
        
        // Upsert documents (some new, some existing)
        const upsertDocs = [
            {
                id: 'custom_doc_1',
                text: 'This is a custom document with a specific ID.',
                embedding: generateRandomVector(384),
                metadata: {
                    category: 'custom',
                    type: 'important'
                }
            },
            {
                id: 'custom_doc_2',
                text: 'Another custom document.',
                embedding: generateRandomVector(384),
                metadata: {
                    category: 'custom',
                    type: 'normal'
                }
            }
        ];
        
        const upsertResult = await documentManager.upsertDocuments(collectionName, upsertDocs);
        console.log('Upsert result:', upsertResult);
        
        // Count documents after upsert
        await documentManager.countDocuments(collectionName);
        
        console.log('\\n=== Delete Operations ===');
        
        // Delete specific documents
        const deleteResult = await documentManager.deleteDocuments(collectionName, {
            ids: ['custom_doc_1']
        });
        console.log('Delete result:', deleteResult);
        
        // Delete documents by metadata
        const deleteByMetadataResult = await documentManager.deleteDocuments(collectionName, {
            where: { category: 'custom' }
        });
        console.log('Delete by metadata result:', deleteByMetadataResult);
        
        // Final count
        await documentManager.countDocuments(collectionName);
        
        console.log('\\n=== Cleanup ===');
        
        // Clean up - delete the collection
        await chromaManager.deleteCollection(collectionName);
        
        // List collections to confirm deletion
        await chromaManager.listCollections();
        
    } catch (error) {
        console.error('Error in basic operations examples:', error);
    }
}

// ==========================================
// COLLECTION UTILITIES
// ==========================================

class CollectionUtils {
    constructor(chromaManager) {
        this.chromaManager = chromaManager;
    }

    /**
     * Get collection statistics
     */
    async getCollectionStats(collectionName) {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            const count = await collection.count();
            
            // Get sample documents to analyze
            const sample = await collection.get({
                limit: 10,
                include: ['metadatas', 'documents']
            });
            
            // Analyze metadata fields
            const metadataFields = new Set();
            sample.metadatas.forEach(metadata => {
                Object.keys(metadata).forEach(key => metadataFields.add(key));
            });
            
            const stats = {
                name: collectionName,
                documentCount: count,
                metadataFields: Array.from(metadataFields),
                sampleTexts: sample.documents.slice(0, 3).map(doc => doc.substring(0, 100))
            };
            
            console.log(`📊 Collection stats for ${collectionName}:`, stats);
            return stats;
        } catch (error) {
            console.error('❌ Error getting collection stats:', error);
            return null;
        }
    }

    /**
     * Export collection data
     */
    async exportCollection(collectionName, format = 'json') {
        try {
            const collection = await this.chromaManager.getCollection(collectionName);
            const data = await collection.get({
                include: ['metadatas', 'documents', 'embeddings']
            });
            
            const exportData = {
                collection: collectionName,
                exportedAt: new Date().toISOString(),
                documentCount: data.ids.length,
                documents: data.ids.map((id, index) => ({
                    id,
                    text: data.documents[index],
                    metadata: data.metadatas[index],
                    embedding: data.embeddings[index]
                }))
            };
            
            console.log(`📤 Exported ${exportData.documentCount} documents from ${collectionName}`);
            return exportData;
        } catch (error) {
            console.error('❌ Error exporting collection:', error);
            return null;
        }
    }

    /**
     * Import collection data
     */
    async importCollection(collectionName, data) {
        try {
            const collection = await this.chromaManager.getOrCreateCollection(collectionName);
            
            const ids = data.documents.map(doc => doc.id);
            const embeddings = data.documents.map(doc => doc.embedding);
            const metadatas = data.documents.map(doc => doc.metadata);
            const documents = data.documents.map(doc => doc.text);
            
            await collection.add({
                ids,
                embeddings,
                metadatas,
                documents
            });
            
            console.log(`📥 Imported ${data.documents.length} documents to ${collectionName}`);
            return { success: true, count: data.documents.length };
        } catch (error) {
            console.error('❌ Error importing collection:', error);
            return { success: false, error: error.message };
        }
    }
}

// Run examples when script is executed directly
if (require.main === module) {
    runBasicOperationsExamples().catch(console.error);
}

module.exports = {
    ChromaManager,
    DocumentManager,
    CollectionUtils,
    generateRandomVector,
    generateSampleDocuments
};