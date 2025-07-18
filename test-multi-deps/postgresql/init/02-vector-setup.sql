-- Vector database specific setup
-- This script sets up additional vector database functionality

-- Create collections table for organizing embeddings
CREATE TABLE IF NOT EXISTS collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Update embeddings table to reference collections
ALTER TABLE embeddings 
ADD COLUMN IF NOT EXISTS collection_id UUID REFERENCES collections(id) ON DELETE CASCADE;

-- Create index on collection_id
CREATE INDEX IF NOT EXISTS idx_embeddings_collection_id ON embeddings(collection_id);

-- Create default collection
INSERT INTO collections (name, description)
VALUES ('default', 'Default collection for embeddings')
ON CONFLICT (name) DO NOTHING;

-- Function to add embedding with automatic collection assignment
CREATE OR REPLACE FUNCTION add_embedding(
    p_content TEXT,
    p_embedding vector(1536),
    p_metadata JSONB DEFAULT '{}',
    p_collection_name VARCHAR(255) DEFAULT 'default'
)
RETURNS UUID
LANGUAGE PLPGSQL
AS $$
DECLARE
    collection_uuid UUID;
    embedding_uuid UUID;
BEGIN
    -- Get or create collection
    SELECT id INTO collection_uuid
    FROM collections
    WHERE name = p_collection_name;
    
    IF collection_uuid IS NULL THEN
        INSERT INTO collections (name)
        VALUES (p_collection_name)
        RETURNING id INTO collection_uuid;
    END IF;
    
    -- Insert embedding
    INSERT INTO embeddings (content, embedding, metadata, collection_id)
    VALUES (p_content, p_embedding, p_metadata, collection_uuid)
    RETURNING id INTO embedding_uuid;
    
    RETURN embedding_uuid;
END;
$$;
