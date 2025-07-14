-- Initial schema migration
-- This is an example migration file

-- Add new columns or tables here
-- ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Example: Add new table
-- CREATE TABLE user_profiles (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     user_id UUID REFERENCES users(id) ON DELETE CASCADE,
--     bio TEXT,
--     avatar_url VARCHAR(255),
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );
