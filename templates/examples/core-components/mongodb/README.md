# MongoDB Component Examples

This directory contains working examples for MongoDB operations that demonstrate best practices and common patterns.

## 📋 Available Examples

### Core Examples
- **example-crud.js** - Basic CRUD operations and queries
- **example-aggregation.js** - Advanced aggregation pipelines
- **example-indexing.js** - Index management and optimization
- **example-transactions.js** - Multi-document transactions
- **example-change-streams.js** - Real-time data monitoring

## 🚀 Setup Instructions

1. **Ensure MongoDB is running:**
   ```bash
   docker-compose up -d mongodb
   ```

2. **Install MongoDB driver:**
   ```bash
   npm install mongodb
   ```

3. **Test connection:**
   ```bash
   mongosh "mongodb://localhost:27017/testdb"
   ```

4. **Run examples:**
   ```bash
   node example-crud.js
   node example-aggregation.js
   node example-indexing.js
   ```

## 📖 Example Details

### example-crud.js
Demonstrates:
- Basic CRUD operations
- Document validation
- Query optimization
- Bulk operations
- Error handling

### example-aggregation.js
Demonstrates:
- Aggregation pipelines
- Complex data transformations
- Grouping and sorting
- Lookup operations
- Performance optimization

### example-indexing.js
Demonstrates:
- Index creation and management
- Compound indexes
- Text search indexes
- Geospatial indexes
- Performance analysis

### example-transactions.js
Demonstrates:
- Multi-document transactions
- ACID compliance
- Session management
- Error handling
- Rollback scenarios

### example-change-streams.js
Demonstrates:
- Real-time data monitoring
- Change stream filters
- Resume tokens
- Event handling
- WebSocket integration

## 🔧 Integration with FastAPI

These examples can be integrated with FastAPI backends using:
- Motor (async MongoDB driver)
- Pydantic models for validation
- ODM libraries like Beanie
- Connection pooling
- Background tasks

## 📝 Notes

- Examples use MongoDB 5.0+ features
- Includes proper error handling
- Demonstrates performance patterns
- Shows security best practices
- Includes monitoring and logging