-- Performance optimization and maintenance setup

-- Enable query timing
SET track_activity_query_size = 1024;
SET log_min_duration_statement = 1000; -- Log queries taking > 1 second

-- Create performance monitoring view
CREATE OR REPLACE VIEW slow_queries AS
SELECT
    query,
    calls,
    total_time,
    mean_time,
    min_time,
    max_time,
    stddev_time
FROM pg_stat_statements
WHERE mean_time > 100 -- queries with mean time > 100ms
ORDER BY mean_time DESC;

-- Create database statistics function
CREATE OR REPLACE FUNCTION db_stats()
RETURNS TABLE (
    table_name TEXT,
    row_count BIGINT,
    total_size TEXT,
    index_size TEXT,
    toast_size TEXT
)
LANGUAGE PLPGSQL
AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname||'.'||tablename AS table_name,
        n_tup_ins - n_tup_del AS row_count,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
        pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS index_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS toast_size
    FROM pg_stat_user_tables
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$;

-- Create maintenance procedures
CREATE OR REPLACE FUNCTION vacuum_analyze_all()
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'VACUUM ANALYZE ' || quote_ident(table_record.schemaname) || '.' || quote_ident(table_record.tablename);
    END LOOP;
END;
$$;
