-- PostgreSQL Migration Examples
-- This file demonstrates database migration patterns and best practices

-- ==========================================
-- MIGRATION STRUCTURE
-- ==========================================

-- Migration tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Function to record migration
CREATE OR REPLACE FUNCTION record_migration(version_num TEXT, description_text TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO schema_migrations (version, description)
    VALUES (version_num, description_text)
    ON CONFLICT (version) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- EXAMPLE MIGRATIONS
-- ==========================================

-- Migration 001: Initial schema setup
-- This would typically be in a separate file: 001_initial_schema.sql
DO $$
BEGIN
    -- Add initial tables (already created in example-schema.sql)
    PERFORM record_migration('001', 'Initial schema setup with users, products, orders');
END $$;

-- Migration 002: Add user preferences
-- File: 002_add_user_preferences.sql
DO $$
BEGIN
    -- Check if migration already applied
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '002') THEN
        
        -- Add new columns to users table
        ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}';
        ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_settings JSONB DEFAULT '{
            "email": true,
            "push": true,
            "sms": false,
            "marketing": false
        }';
        
        -- Add index for preferences
        CREATE INDEX IF NOT EXISTS idx_users_preferences ON users USING GIN (preferences);
        
        -- Record migration
        PERFORM record_migration('002', 'Add user preferences and notification settings');
    END IF;
END $$;

-- Migration 003: Add product reviews table
-- File: 003_add_product_reviews.sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '003') THEN
        
        -- Create reviews table (already exists in schema, but showing pattern)
        CREATE TABLE IF NOT EXISTS reviews (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
            title VARCHAR(255),
            comment TEXT,
            is_verified BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Add indexes
        CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
        CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
        CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
        
        PERFORM record_migration('003', 'Add product reviews table');
    END IF;
END $$;

-- Migration 004: Add full-text search to products
-- File: 004_add_fulltext_search.sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '004') THEN
        
        -- Add search vector column
        ALTER TABLE products ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
        
        -- Create GIN index for full-text search
        CREATE INDEX IF NOT EXISTS idx_products_search ON products USING GIN (search_vector);
        
        -- Update existing products with search vectors
        UPDATE products 
        SET search_vector = to_tsvector('english', 
            COALESCE(name, '') || ' ' || 
            COALESCE(description, '') || ' ' || 
            COALESCE(array_to_string(tags, ' '), '')
        )
        WHERE search_vector IS NULL;
        
        -- Create trigger function for automatic updates
        CREATE OR REPLACE FUNCTION update_product_search_vector()
        RETURNS TRIGGER AS $trigger$
        BEGIN
            NEW.search_vector = to_tsvector('english', 
                COALESCE(NEW.name, '') || ' ' || 
                COALESCE(NEW.description, '') || ' ' || 
                COALESCE(array_to_string(NEW.tags, ' '), '')
            );
            RETURN NEW;
        END;
        $trigger$ LANGUAGE plpgsql;
        
        -- Create trigger
        DROP TRIGGER IF EXISTS update_products_search_vector ON products;
        CREATE TRIGGER update_products_search_vector
            BEFORE INSERT OR UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION update_product_search_vector();
        
        PERFORM record_migration('004', 'Add full-text search to products');
    END IF;
END $$;

-- Migration 005: Add audit logging
-- File: 005_add_audit_logging.sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '005') THEN
        
        -- Create audit log table (already exists in schema)
        CREATE TABLE IF NOT EXISTS audit_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            table_name VARCHAR(50) NOT NULL,
            record_id UUID NOT NULL,
            action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
            old_values JSONB,
            new_values JSONB,
            user_id UUID REFERENCES users(id) ON DELETE SET NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON audit_logs(table_name);
        CREATE INDEX IF NOT EXISTS idx_audit_logs_record_id ON audit_logs(record_id);
        CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
        
        -- Create audit trigger function
        CREATE OR REPLACE FUNCTION audit_trigger()
        RETURNS TRIGGER AS $audit$
        BEGIN
            INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values)
            VALUES (
                TG_TABLE_NAME::TEXT,
                COALESCE(NEW.id, OLD.id),
                TG_OP,
                CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
                CASE WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW) ELSE to_jsonb(NEW) END
            );
            RETURN COALESCE(NEW, OLD);
        END;
        $audit$ LANGUAGE plpgsql;
        
        -- Add audit triggers to important tables
        CREATE TRIGGER audit_users_trigger
            AFTER INSERT OR UPDATE OR DELETE ON users
            FOR EACH ROW EXECUTE FUNCTION audit_trigger();
            
        CREATE TRIGGER audit_products_trigger
            AFTER INSERT OR UPDATE OR DELETE ON products
            FOR EACH ROW EXECUTE FUNCTION audit_trigger();
            
        CREATE TRIGGER audit_orders_trigger
            AFTER INSERT OR UPDATE OR DELETE ON orders
            FOR EACH ROW EXECUTE FUNCTION audit_trigger();
        
        PERFORM record_migration('005', 'Add audit logging system');
    END IF;
END $$;

-- Migration 006: Add vector embeddings for AI features
-- File: 006_add_vector_embeddings.sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '006') THEN
        
        -- Enable vector extension
        CREATE EXTENSION IF NOT EXISTS vector;
        
        -- Create embeddings table (already exists in schema)
        CREATE TABLE IF NOT EXISTS product_embeddings (
            product_id UUID PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
            embedding VECTOR(1536), -- OpenAI embedding size
            model_name VARCHAR(100) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Create vector indexes for similarity search
        CREATE INDEX IF NOT EXISTS idx_product_embeddings_cosine 
            ON product_embeddings USING ivfflat (embedding vector_cosine_ops);
        CREATE INDEX IF NOT EXISTS idx_product_embeddings_l2 
            ON product_embeddings USING ivfflat (embedding vector_l2_ops);
        
        PERFORM record_migration('006', 'Add vector embeddings for AI features');
    END IF;
END $$;

-- Migration 007: Add user session management
-- File: 007_add_user_sessions.sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '007') THEN
        
        -- Create sessions table (already exists in schema)
        CREATE TABLE IF NOT EXISTS user_sessions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            session_token VARCHAR(255) UNIQUE NOT NULL,
            ip_address INET,
            user_agent TEXT,
            is_active BOOLEAN DEFAULT TRUE,
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);
        
        -- Create cleanup function for expired sessions
        CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
        RETURNS INTEGER AS $cleanup$
        DECLARE
            deleted_count INTEGER;
        BEGIN
            DELETE FROM user_sessions 
            WHERE expires_at < CURRENT_TIMESTAMP OR is_active = FALSE;
            
            GET DIAGNOSTICS deleted_count = ROW_COUNT;
            RETURN deleted_count;
        END;
        $cleanup$ LANGUAGE plpgsql;
        
        PERFORM record_migration('007', 'Add user session management');
    END IF;
END $$;

-- Migration 008: Add product categories hierarchy
-- File: 008_add_category_hierarchy.sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '008') THEN
        
        -- Add parent_id to categories for hierarchy
        ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES categories(id) ON DELETE CASCADE;
        ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
        ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
        
        -- Add constraint to prevent self-referencing
        ALTER TABLE categories ADD CONSTRAINT IF NOT EXISTS no_self_reference 
            CHECK (id != parent_id);
        
        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
        CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order);
        
        -- Create function to get category path
        CREATE OR REPLACE FUNCTION get_category_path(category_id UUID)
        RETURNS TEXT AS $path$
        DECLARE
            result TEXT := '';
            current_id UUID := category_id;
            current_name TEXT;
            parent_id UUID;
        BEGIN
            WHILE current_id IS NOT NULL LOOP
                SELECT name, categories.parent_id 
                INTO current_name, parent_id
                FROM categories 
                WHERE id = current_id;
                
                IF current_name IS NULL THEN
                    EXIT;
                END IF;
                
                IF result = '' THEN
                    result := current_name;
                ELSE
                    result := current_name || ' > ' || result;
                END IF;
                
                current_id := parent_id;
            END LOOP;
            
            RETURN result;
        END;
        $path$ LANGUAGE plpgsql;
        
        PERFORM record_migration('008', 'Add category hierarchy support');
    END IF;
END $$;

-- ==========================================
-- ROLLBACK EXAMPLES
-- ==========================================

-- Function to rollback migration
CREATE OR REPLACE FUNCTION rollback_migration(version_num TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM schema_migrations WHERE version = version_num;
    RAISE NOTICE 'Migration % rolled back. Manual cleanup of changes may be required.', version_num;
END;
$$ LANGUAGE plpgsql;

-- Example rollback for migration 008
CREATE OR REPLACE FUNCTION rollback_008()
RETURNS VOID AS $$
BEGIN
    -- Drop function
    DROP FUNCTION IF EXISTS get_category_path(UUID);
    
    -- Drop indexes
    DROP INDEX IF EXISTS idx_categories_parent_id;
    DROP INDEX IF EXISTS idx_categories_sort_order;
    
    -- Drop constraint
    ALTER TABLE categories DROP CONSTRAINT IF EXISTS no_self_reference;
    
    -- Drop columns
    ALTER TABLE categories DROP COLUMN IF EXISTS parent_id;
    ALTER TABLE categories DROP COLUMN IF EXISTS sort_order;
    ALTER TABLE categories DROP COLUMN IF EXISTS is_active;
    
    -- Remove migration record
    PERFORM rollback_migration('008');
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- MIGRATION UTILITIES
-- ==========================================

-- Check if migration exists
CREATE OR REPLACE FUNCTION migration_exists(version_num TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM schema_migrations WHERE version = version_num);
END;
$$ LANGUAGE plpgsql;

-- Get applied migrations
CREATE OR REPLACE FUNCTION get_applied_migrations()
RETURNS TABLE(version TEXT, applied_at TIMESTAMP WITH TIME ZONE, description TEXT) AS $$
BEGIN
    RETURN QUERY 
    SELECT sm.version, sm.applied_at, sm.description
    FROM schema_migrations sm
    ORDER BY sm.version;
END;
$$ LANGUAGE plpgsql;

-- Get migration status
CREATE OR REPLACE FUNCTION get_migration_status()
RETURNS TABLE(
    total_migrations INTEGER,
    applied_migrations INTEGER,
    pending_migrations INTEGER,
    last_migration TEXT,
    last_applied TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        8 as total_migrations, -- Update this as you add more migrations
        (SELECT COUNT(*)::INTEGER FROM schema_migrations) as applied_migrations,
        (8 - (SELECT COUNT(*)::INTEGER FROM schema_migrations)) as pending_migrations,
        (SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1) as last_migration,
        (SELECT applied_at FROM schema_migrations ORDER BY applied_at DESC LIMIT 1) as last_applied;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- DATA MIGRATION EXAMPLES
-- ==========================================

-- Example: Migrate user data to new preferences format
CREATE OR REPLACE FUNCTION migrate_user_preferences()
RETURNS VOID AS $$
BEGIN
    -- Update users who don't have preferences set
    UPDATE users 
    SET preferences = jsonb_build_object(
        'theme', 'light',
        'language', 'en',
        'timezone', 'UTC',
        'email_notifications', true,
        'push_notifications', true
    )
    WHERE preferences = '{}' OR preferences IS NULL;
    
    RAISE NOTICE 'User preferences migration completed';
END;
$$ LANGUAGE plpgsql;

-- Example: Migrate product data to include search vectors
CREATE OR REPLACE FUNCTION migrate_product_search_vectors()
RETURNS VOID AS $$
DECLARE
    processed_count INTEGER := 0;
BEGIN
    -- Update products without search vectors
    UPDATE products 
    SET search_vector = to_tsvector('english', 
        COALESCE(name, '') || ' ' || 
        COALESCE(description, '') || ' ' || 
        COALESCE(array_to_string(tags, ' '), '')
    )
    WHERE search_vector IS NULL;
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    RAISE NOTICE 'Updated search vectors for % products', processed_count;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- PERFORMANCE OPTIMIZATION MIGRATIONS
-- ==========================================

-- Add missing indexes based on query patterns
CREATE OR REPLACE FUNCTION add_performance_indexes()
RETURNS VOID AS $$
BEGIN
    -- Composite indexes for common query patterns
    CREATE INDEX IF NOT EXISTS idx_orders_user_status 
        ON orders(user_id, status) WHERE status IN ('pending', 'processing');
    
    CREATE INDEX IF NOT EXISTS idx_products_category_active 
        ON products(category_id, is_active) WHERE is_active = true;
    
    CREATE INDEX IF NOT EXISTS idx_reviews_product_approved 
        ON reviews(product_id, is_approved) WHERE is_approved = true;
    
    -- Partial indexes for better performance
    CREATE INDEX IF NOT EXISTS idx_users_active_recent 
        ON users(created_at) WHERE status = 'active' AND created_at >= CURRENT_DATE - INTERVAL '30 days';
    
    RAISE NOTICE 'Performance indexes added';
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- EXAMPLE USAGE
-- ==========================================

-- Check current migration status
-- SELECT * FROM get_migration_status();

-- Get all applied migrations
-- SELECT * FROM get_applied_migrations();

-- Check if specific migration is applied
-- SELECT migration_exists('005');

-- Apply data migrations
-- SELECT migrate_user_preferences();
-- SELECT migrate_product_search_vectors();

-- Add performance improvements
-- SELECT add_performance_indexes();

-- Cleanup expired sessions
-- SELECT cleanup_expired_sessions();