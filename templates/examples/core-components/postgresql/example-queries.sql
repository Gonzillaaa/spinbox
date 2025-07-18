-- PostgreSQL Query Examples
-- This file demonstrates common query patterns and best practices

-- ==========================================
-- BASIC CRUD OPERATIONS
-- ==========================================

-- Create a new user
INSERT INTO users (email, username, password_hash, first_name, last_name, status)
VALUES ('alice@example.com', 'alice', crypt('password123', gen_salt('bf')), 'Alice', 'Smith', 'active')
RETURNING id, email, username, first_name, last_name, created_at;

-- Read user by ID
SELECT 
    id,
    email,
    username,
    first_name,
    last_name,
    status,
    created_at,
    last_login,
    login_count
FROM users 
WHERE id = 'user-uuid-here';

-- Update user profile
UPDATE users 
SET 
    first_name = 'Alice',
    last_name = 'Johnson',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'user-uuid-here'
RETURNING id, first_name, last_name, updated_at;

-- Soft delete (mark as inactive)
UPDATE users 
SET 
    status = 'inactive',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'user-uuid-here';

-- Hard delete (use with caution)
DELETE FROM users WHERE id = 'user-uuid-here';

-- ==========================================
-- ADVANCED QUERYING
-- ==========================================

-- Get users with pagination and filtering
SELECT 
    id,
    email,
    username,
    first_name,
    last_name,
    status,
    created_at
FROM users
WHERE 
    status = 'active'
    AND created_at >= '2024-01-01'
    AND (
        first_name ILIKE '%john%' 
        OR last_name ILIKE '%john%'
        OR email ILIKE '%john%'
    )
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- Get user count by status
SELECT 
    status,
    COUNT(*) as user_count
FROM users
GROUP BY status
ORDER BY user_count DESC;

-- Get users who haven't logged in recently
SELECT 
    id,
    email,
    username,
    first_name,
    last_name,
    last_login,
    created_at
FROM users
WHERE 
    status = 'active'
    AND (
        last_login IS NULL 
        OR last_login < CURRENT_DATE - INTERVAL '30 days'
    )
ORDER BY COALESCE(last_login, created_at) ASC;

-- ==========================================
-- COMPLEX JOINS AND RELATIONSHIPS
-- ==========================================

-- Get products with category information
SELECT 
    p.id,
    p.name,
    p.slug,
    p.price,
    p.stock_quantity,
    p.is_active,
    c.name as category_name,
    c.slug as category_slug
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.is_active = true
ORDER BY p.name;

-- Get product with all variants
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.price as base_price,
    pv.id as variant_id,
    pv.name as variant_name,
    pv.price as variant_price,
    pv.stock_quantity as variant_stock,
    pv.attributes as variant_attributes
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.id = 'product-uuid-here'
ORDER BY pv.name;

-- Get orders with items and user information
SELECT 
    o.id as order_id,
    o.order_number,
    o.status,
    o.total_amount,
    o.created_at,
    u.email as user_email,
    u.first_name,
    u.last_name,
    oi.product_name,
    oi.quantity,
    oi.unit_price,
    oi.total_price
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY o.created_at DESC, oi.product_name;

-- Get user's order history with summary
SELECT 
    u.id as user_id,
    u.email,
    u.first_name,
    u.last_name,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as average_order_value,
    MAX(o.created_at) as last_order_date,
    MIN(o.created_at) as first_order_date
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.email, u.first_name, u.last_name
HAVING COUNT(o.id) > 0
ORDER BY total_spent DESC;

-- ==========================================
-- ANALYTICS AND REPORTING
-- ==========================================

-- Daily sales report
SELECT 
    DATE(created_at) as order_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as average_order_value,
    COUNT(DISTINCT user_id) as unique_customers
FROM orders
WHERE 
    created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND status NOT IN ('cancelled', 'refunded')
GROUP BY DATE(created_at)
ORDER BY order_date DESC;

-- Top selling products
SELECT 
    p.id,
    p.name,
    p.price,
    COUNT(oi.id) as times_ordered,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.total_price) as total_revenue
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
WHERE 
    o.created_at >= CURRENT_DATE - INTERVAL '90 days'
    AND o.status NOT IN ('cancelled', 'refunded')
GROUP BY p.id, p.name, p.price
ORDER BY total_revenue DESC
LIMIT 10;

-- Customer lifetime value
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    DATE_PART('day', MAX(o.created_at) - MIN(o.created_at)) as customer_lifespan_days,
    MIN(o.created_at) as first_order,
    MAX(o.created_at) as last_order
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY u.id, u.email, u.first_name, u.last_name
HAVING COUNT(o.id) >= 2
ORDER BY lifetime_value DESC;

-- Product performance analysis
SELECT 
    p.id,
    p.name,
    p.price,
    p.stock_quantity,
    COUNT(r.id) as review_count,
    AVG(r.rating) as average_rating,
    COUNT(oi.id) as order_count,
    SUM(oi.quantity) as total_sold,
    SUM(oi.total_price) as total_revenue,
    CASE 
        WHEN COUNT(oi.id) > 0 THEN SUM(oi.total_price) / COUNT(oi.id)
        ELSE 0
    END as avg_revenue_per_order
FROM products p
LEFT JOIN reviews r ON p.id = r.product_id AND r.is_approved = true
LEFT JOIN order_items oi ON p.id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.id AND o.status NOT IN ('cancelled', 'refunded')
WHERE p.is_active = true
GROUP BY p.id, p.name, p.price, p.stock_quantity
ORDER BY total_revenue DESC NULLS LAST;

-- ==========================================
-- FULL-TEXT SEARCH EXAMPLES
-- ==========================================

-- Simple text search
SELECT 
    id,
    name,
    description,
    price,
    ts_rank(search_vector, plainto_tsquery('english', 'wireless headphones')) as rank
FROM products
WHERE search_vector @@ plainto_tsquery('english', 'wireless headphones')
ORDER BY rank DESC;

-- Advanced text search with filters
SELECT 
    p.id,
    p.name,
    p.description,
    p.price,
    c.name as category,
    ts_rank(p.search_vector, query) as rank
FROM products p
JOIN categories c ON p.category_id = c.id,
plainto_tsquery('english', 'bluetooth speaker') as query
WHERE 
    p.search_vector @@ query
    AND p.is_active = true
    AND p.price BETWEEN 50 AND 300
ORDER BY rank DESC, p.price ASC;

-- Search with autocomplete suggestions
SELECT DISTINCT
    regexp_split_to_table(
        ts_lexize('english_stem', word), 
        '\s+'
    ) as suggestion
FROM (
    SELECT unnest(string_to_array(lower('wireless headphones'), ' ')) as word
) words
WHERE word IS NOT NULL
LIMIT 10;

-- ==========================================
-- WINDOW FUNCTIONS
-- ==========================================

-- Rank customers by spending within each month
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    DATE_TRUNC('month', o.created_at) as order_month,
    SUM(o.total_amount) as monthly_spending,
    RANK() OVER (
        PARTITION BY DATE_TRUNC('month', o.created_at) 
        ORDER BY SUM(o.total_amount) DESC
    ) as spending_rank
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE 
    o.created_at >= CURRENT_DATE - INTERVAL '6 months'
    AND o.status NOT IN ('cancelled', 'refunded')
GROUP BY u.id, u.email, u.first_name, u.last_name, DATE_TRUNC('month', o.created_at)
ORDER BY order_month DESC, spending_rank ASC;

-- Calculate running totals
SELECT 
    DATE(created_at) as order_date,
    SUM(total_amount) as daily_sales,
    SUM(SUM(total_amount)) OVER (
        ORDER BY DATE(created_at) 
        ROWS UNBOUNDED PRECEDING
    ) as running_total
FROM orders
WHERE 
    created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND status NOT IN ('cancelled', 'refunded')
GROUP BY DATE(created_at)
ORDER BY order_date;

-- ==========================================
-- JSON OPERATIONS
-- ==========================================

-- Query products with specific attributes
SELECT 
    id,
    name,
    metadata,
    metadata->>'brand' as brand,
    metadata->>'color' as color,
    (metadata->>'weight')::numeric as weight
FROM products
WHERE 
    metadata ? 'brand'
    AND metadata->>'brand' = 'Apple'
    AND (metadata->>'color') IN ('black', 'white');

-- Update JSON fields
UPDATE products 
SET metadata = jsonb_set(
    metadata, 
    '{specifications}', 
    '{"connectivity": "bluetooth", "battery_life": "20 hours"}'
)
WHERE id = 'product-uuid-here';

-- Query user preferences
SELECT 
    u.id,
    u.email,
    up.preferences->>'theme' as theme,
    up.preferences->>'language' as language,
    (up.preferences->>'notifications_enabled')::boolean as notifications
FROM users u
JOIN user_profiles up ON u.id = up.user_id
WHERE up.preferences ? 'theme';

-- ==========================================
-- VECTOR SIMILARITY SEARCH (AI/ML)
-- ==========================================

-- Find similar products using vector embeddings
SELECT 
    p.id,
    p.name,
    p.price,
    1 - (pe.embedding <=> target.embedding) as similarity_score
FROM products p
JOIN product_embeddings pe ON p.id = pe.product_id
CROSS JOIN (
    SELECT embedding 
    FROM product_embeddings 
    WHERE product_id = 'target-product-uuid-here'
) target
WHERE p.id != 'target-product-uuid-here'
ORDER BY pe.embedding <=> target.embedding
LIMIT 10;

-- ==========================================
-- PERFORMANCE OPTIMIZATION EXAMPLES
-- ==========================================

-- Use indexes effectively
EXPLAIN ANALYZE
SELECT *
FROM products
WHERE 
    category_id = 'category-uuid-here'
    AND price BETWEEN 100 AND 500
    AND is_active = true;

-- Avoid N+1 queries with proper joins
SELECT 
    p.id,
    p.name,
    p.price,
    ARRAY_AGG(
        DISTINCT jsonb_build_object(
            'id', pv.id,
            'name', pv.name,
            'price', pv.price,
            'stock', pv.stock_quantity
        )
    ) FILTER (WHERE pv.id IS NOT NULL) as variants
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.is_active = true
GROUP BY p.id, p.name, p.price
ORDER BY p.name;

-- ==========================================
-- MAINTENANCE AND MONITORING
-- ==========================================

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY schemaname, tablename, attname;

-- Monitor query performance
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    max_time,
    stddev_time
FROM pg_stat_statements
WHERE query LIKE '%products%'
ORDER BY total_time DESC
LIMIT 10;

-- Check index usage
SELECT 
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- ==========================================
-- BACKUP AND RECOVERY
-- ==========================================

-- Create a backup of specific tables
-- (Run from command line)
-- pg_dump -h localhost -U postgres -t users -t orders -t products database_name > backup.sql

-- Restore from backup
-- psql -h localhost -U postgres database_name < backup.sql

-- ==========================================
-- COMMON UTILITY FUNCTIONS
-- ==========================================

-- Generate random test data
INSERT INTO users (email, username, password_hash, first_name, last_name, status)
SELECT 
    'user' || generate_series || '@example.com',
    'user' || generate_series,
    crypt('password123', gen_salt('bf')),
    'First' || generate_series,
    'Last' || generate_series,
    CASE 
        WHEN random() < 0.8 THEN 'active'
        WHEN random() < 0.9 THEN 'inactive'
        ELSE 'pending'
    END
FROM generate_series(1, 100);

-- Clean up old sessions
DELETE FROM user_sessions 
WHERE expires_at < CURRENT_TIMESTAMP;

-- Archive old orders
INSERT INTO orders_archive 
SELECT * FROM orders 
WHERE created_at < CURRENT_DATE - INTERVAL '2 years';

DELETE FROM orders 
WHERE created_at < CURRENT_DATE - INTERVAL '2 years';

-- Update product search vectors
UPDATE products 
SET search_vector = to_tsvector('english', 
    COALESCE(name, '') || ' ' || 
    COALESCE(description, '') || ' ' || 
    COALESCE(array_to_string(tags, ' '), '')
)
WHERE search_vector IS NULL;