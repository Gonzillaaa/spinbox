# PostgreSQL Component Examples

This directory contains working examples for PostgreSQL database operations that demonstrate best practices and common patterns.

## 📋 Available Examples

### Core Examples
- **example-schema.sql** - Database schema design with best practices
- **example-queries.sql** - Common SQL query patterns and optimizations
- **example-migrations.sql** - Database migration examples

## 🚀 Setup Instructions

1. **Ensure PostgreSQL is running:**
   ```bash
   docker-compose up -d postgres
   ```

2. **Connect to database:**
   ```bash
   ./scripts/connect.sh
   ```

3. **Run schema setup:**
   ```bash
   psql -U postgres -d your_database < example-schema.sql
   ```

4. **Run example queries:**
   ```bash
   psql -U postgres -d your_database < example-queries.sql
   ```

## 📖 Example Details

### example-schema.sql
Demonstrates:
- Proper table design with constraints
- Index creation for performance
- Foreign key relationships
- Data types best practices
- Security considerations

### example-queries.sql
Demonstrates:
- CRUD operations
- Complex joins
- Aggregations and analytics
- Performance optimization
- Common query patterns

### example-migrations.sql
Demonstrates:
- Schema evolution
- Data migration strategies
- Index management
- Rollback procedures
- Version control

## 🔧 Integration with FastAPI

These examples are designed to work with SQLAlchemy and FastAPI. See the `fastapi-postgresql` combination examples for ORM integration patterns.

## 📝 Notes

- All examples use PostgreSQL 15+ features
- Includes PGVector extension for AI/ML embeddings
- Examples follow PostgreSQL best practices
- Proper error handling and transaction management
- Performance optimizations included