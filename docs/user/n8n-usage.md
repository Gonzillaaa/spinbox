# n8n Workflow Automation Usage

Complete guide to using n8n (pronounced "n-eight-n") workflow automation platform in your Spinbox projects.

## Overview

n8n is a free and source-available workflow automation tool designed for technical users. It allows you to connect different services and create powerful automation workflows through a visual workflow editor.

### What is n8n?

n8n is a **workflow automation platform** that enables you to:
- **Connect APIs and services** - Integrate hundreds of different apps and services
- **Automate repetitive tasks** - Build workflows that run automatically based on triggers
- **Process data pipelines** - Transform and route data between different systems
- **Create complex business logic** - Use branching, loops, and conditional logic
- **Schedule tasks** - Run workflows on time-based schedules
- **Handle webhooks** - Respond to real-time events from external services

### Key Features

- **Visual workflow editor** - Drag-and-drop interface for building workflows
- **300+ integrations** - Pre-built nodes for popular services (Slack, GitHub, Google Sheets, etc.)
- **Custom code execution** - Run JavaScript/Python code within workflows
- **Database storage** - Persistent workflow execution history and data
- **REST API** - Programmatic workflow management
- **Self-hosted** - Full control over your automation platform

## Creating n8n Projects

### Basic n8n Project

Create a standalone n8n workflow automation environment:

```bash
spinbox create workflow-app --n8n
```

This creates:
- **n8n service** running on port 5678
- **Web interface** accessible at http://localhost:5678
- **Volume persistence** for workflow data
- **Environment configuration** with security defaults

### n8n with PostgreSQL Integration

For production workflows with persistent data storage:

```bash
spinbox create workflow-db --n8n --postgresql
```

This creates:
- **n8n configured with PostgreSQL** as the database backend
- **Automatic database setup** with proper connection configuration
- **Enhanced performance** for workflow execution history
- **Scalable storage** for large automation workflows

### Advanced Configuration

Combine n8n with other components for complex automation scenarios:

```bash
# n8n with Redis for caching and queues
spinbox create automation-platform --n8n --postgresql --redis

# Full-stack with n8n automation
spinbox create full-automation --fastapi --nextjs --n8n --postgresql
```

## Configuration

### Port Configuration

n8n runs on **port 5678** by default:
- **Web interface**: http://localhost:5678
- **API endpoint**: http://localhost:5678/api
- **Webhook endpoint**: http://localhost:5678/webhook

### Default Security Settings

Spinbox configures n8n with secure defaults:

```env
# Basic Authentication (enabled by default)
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme

# Timezone Configuration
GENERIC_TIMEZONE=America/New_York
TZ=America/New_York

# Encryption
N8N_ENCRYPTION_KEY=your-encryption-key-here

# Webhook Configuration
WEBHOOK_URL=http://localhost:5678/
```

### Environment Configuration

Located in `n8n/.env.example`:

```env
# n8n Configuration
# Copy to .env and customize

# Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme

# Database (when using PostgreSQL)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=your-project-name
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=postgres

# Security
N8N_ENCRYPTION_KEY=your-encryption-key-here

# Network Configuration
WEBHOOK_URL=http://localhost:5678/
GENERIC_TIMEZONE=America/New_York
TZ=America/New_York

# Optional: Email Configuration
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=your-smtp-host
N8N_SMTP_PORT=587
N8N_SMTP_USER=your-email@example.com
N8N_SMTP_PASS=your-email-password
```

### PostgreSQL Integration

When using `--n8n --postgresql`, n8n automatically configures to use PostgreSQL as its database:

- **Database name**: Same as your project name
- **Connection**: Automatic configuration via Docker networking
- **Performance**: Better handling of workflow execution history
- **Persistence**: Reliable data storage for production use

## Getting Started

### 1. Create and Start Project

```bash
# Create n8n project
spinbox create my-workflows --n8n --postgresql

# Navigate to project
cd my-workflows

# Start services
docker-compose up -d
```

### 2. Access n8n Web Interface

1. **Open browser** to http://localhost:5678
2. **Login** with default credentials:
   - Username: `admin`
   - Password: `changeme`
3. **Change password** immediately after first login

### 3. Create Your First Workflow

1. **Click "Add workflow"** in the n8n interface
2. **Choose a trigger node** (e.g., Schedule Trigger, Webhook, Manual Trigger)
3. **Add action nodes** to process data
4. **Configure connections** between nodes
5. **Test execution** to verify workflow works
6. **Save and activate** workflow

## Common Use Cases

### API Integration Workflows

```bash
# Example workflow: Sync data between services
# GitHub Issues → Process → Slack Notification
```

**Nodes typically used:**
- **GitHub Trigger** - Monitor new issues
- **Function Node** - Transform issue data
- **Slack Node** - Send notification

### Data Processing Pipelines

```bash
# Example: CSV processing workflow
# Schedule Trigger → HTTP Request → CSV Processing → Database Storage
```

**Nodes typically used:**
- **Cron Trigger** - Schedule execution
- **HTTP Request** - Fetch data
- **Spreadsheet File** - Process CSV
- **Postgres** - Store results

### Webhook Automation

```bash
# Example: Form submission processing
# Webhook Trigger → Validation → Email → Database
```

**Nodes typically used:**
- **Webhook Trigger** - Receive form data
- **Function** - Validate input
- **Email** - Send confirmation
- **Database** - Store submission

## Integration with Other Components

### n8n + FastAPI

Create API endpoints that trigger n8n workflows:

```python
# FastAPI endpoint that triggers n8n workflow
import requests

@app.post("/trigger-workflow")
def trigger_workflow(data: dict):
    n8n_webhook = "http://n8n:5678/webhook/your-webhook-id"
    response = requests.post(n8n_webhook, json=data)
    return {"status": "triggered", "n8n_response": response.json()}
```

### n8n + Next.js

Build admin interfaces for workflow management:

```typescript
// Next.js component to display workflow status
export default function WorkflowDashboard() {
  const [workflows, setWorkflows] = useState([]);
  
  useEffect(() => {
    // Fetch workflow status from n8n API
    fetch('http://localhost:5678/api/workflows')
      .then(res => res.json())
      .then(data => setWorkflows(data));
  }, []);
  
  return (
    <div>
      {workflows.map(workflow => (
        <WorkflowCard key={workflow.id} workflow={workflow} />
      ))}
    </div>
  );
}
```

### n8n + PostgreSQL Data

Access PostgreSQL data directly in workflows:

**PostgreSQL Node Configuration:**
- Host: `postgres` (Docker service name)
- Port: `5432`
- Database: Your project name
- User: `postgres`
- Password: `postgres`

## Security Best Practices

### Authentication

1. **Change default password** immediately after setup
2. **Use strong passwords** for production environments
3. **Consider OAuth** integration for team access
4. **Enable 2FA** if available in your n8n version

### Environment Variables

1. **Never commit `.env` files** to version control
2. **Use unique encryption keys** for each environment
3. **Rotate credentials** regularly
4. **Limit webhook access** with proper validation

### Network Security

1. **Use HTTPS** in production environments
2. **Restrict port access** to necessary services only
3. **Implement rate limiting** for webhook endpoints
4. **Monitor workflow executions** for suspicious activity

## Troubleshooting

### Common Issues

**n8n won't start:**
```bash
# Check container logs
docker-compose logs n8n

# Verify port availability
netstat -an | grep 5678
```

**Database connection issues:**
```bash
# Verify PostgreSQL is running
docker-compose ps postgres

# Check database connectivity
docker-compose exec n8n ping postgres
```

**Workflow execution failures:**
- Check node configuration and credentials
- Verify API endpoints and authentication
- Review execution logs in n8n interface
- Test nodes individually before chaining

### Performance Optimization

**For heavy workflows:**
1. **Use PostgreSQL backend** instead of SQLite
2. **Increase container resources** in Docker Compose
3. **Optimize workflow logic** to reduce API calls
4. **Use caching** where appropriate
5. **Monitor execution times** and bottlenecks

### Backup and Recovery

**Workflow backup:**
```bash
# Export workflows via n8n API
curl -X GET "http://localhost:5678/api/workflows" \
  -u "admin:your-password" > workflows-backup.json

# Import workflows
curl -X POST "http://localhost:5678/api/workflows" \
  -u "admin:your-password" \
  -H "Content-Type: application/json" \
  -d @workflows-backup.json
```

**Database backup (PostgreSQL):**
```bash
# Backup workflow data
docker-compose exec postgres pg_dump -U postgres your-project-name > n8n-backup.sql

# Restore workflow data
docker-compose exec postgres psql -U postgres your-project-name < n8n-backup.sql
```

## Advanced Features

### Custom Nodes

Create custom n8n nodes for specialized functionality:
1. **Follow n8n node development guide**
2. **Install via npm** in your custom n8n image
3. **Mount custom nodes** via Docker volumes

### Scaling n8n

For high-volume workflows:
1. **Use external database** (PostgreSQL)
2. **Implement Redis** for queue management
3. **Consider n8n clustering** for enterprise use
4. **Monitor resource usage** and scale accordingly

## Resources

### Documentation
- **n8n Official Docs**: https://docs.n8n.io/
- **n8n Community**: https://community.n8n.io/
- **Workflow Templates**: https://n8n.io/workflows/

### Integration Examples
- **GitHub Automation**: Issue tracking and PR workflows
- **Slack Bots**: Automated notifications and responses  
- **Data Sync**: CRM to marketing platform synchronization
- **Monitoring**: System health checks and alerting

### API Reference
- **n8n REST API**: http://localhost:5678/api-docs
- **Webhook Endpoints**: http://localhost:5678/webhook/{workflow-id}
- **Workflow Management**: Programmatic workflow control

---

This guide covers the essential aspects of using n8n in your Spinbox projects. For detailed workflow creation and advanced automation techniques, refer to the [official n8n documentation](https://docs.n8n.io/).