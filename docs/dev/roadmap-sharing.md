# Roadmap: Project Sharing & Team Collaboration

## Vision

Enable Spinbox projects to be easily shared with teammates, ensuring everyone gets the exact same development environment with minimal setup time.

---

## Current State (What Already Works)

### Git-Based Sharing

The simplest sharing method already works out of the box:

```bash
# Developer A creates and pushes project
spinbox create myapp --fastapi --postgresql
cd myapp
git init && git add . && git commit -m "Initial project"
git remote add origin <repo-url>
git push -u origin main

# Developer B clones and opens
git clone <repo-url>
cd myapp
# Open in VS Code → "Reopen in Container" prompt appears
```

**What gets shared via Git:**
- `.devcontainer/devcontainer.json` - Container configuration
- `.devcontainer/Dockerfile` - Development image definition
- `docker-compose.yml` - Service definitions (PostgreSQL, Redis, etc.)
- `.config/project.conf` - Spinbox project configuration
- Application code, requirements.txt, package.json, etc.

**Advantages:**
- Zero additional tooling required
- Works with any Git hosting (GitHub, GitLab, Bitbucket)
- Full version control of environment configuration
- DevContainer spec is widely supported (VS Code, GitHub Codespaces, JetBrains)

**Limitations:**
- Each developer builds Docker image locally (2-5 minutes first time)
- Large base images need to be pulled (Python, Node, etc.)
- No way to share "golden" pre-configured images

---

## Phase 1: Pre-built DevContainer Images

### Problem Statement

When a new teammate clones a project, they must:
1. Pull base images (python:3.11-slim, etc.) - 1-2 minutes
2. Build the DevContainer image (install tools, dependencies) - 2-5 minutes
3. Start services (PostgreSQL, Redis, etc.) - 30 seconds

Total: 3-8 minutes of waiting on first setup.

### Proposed Solution

Allow project owners to build and publish DevContainer images to a registry, so teammates can pull pre-built images instead of building.

### New Command

```bash
spinbox publish --devcontainer [OPTIONS]

OPTIONS:
    --registry REGISTRY    Docker registry (default: docker.io)
    --name NAME            Image name (default: project name)
    --tag TAG              Image tag (default: latest)
    --push                 Push to registry after building (default: true)
    --no-push              Build only, don't push
```

### Workflow

**Project owner (one-time setup):**
```bash
cd myproject
spinbox publish --devcontainer --name myorg/myproject-dev
# Builds image and pushes to Docker Hub
# Updates devcontainer.json to reference the image
```

**Generated devcontainer.json update:**
```json
{
  "name": "myproject",
  "image": "myorg/myproject-dev:latest",
  // ... rest of config
}
```

**Teammate experience:**
```bash
git clone <repo-url>
cd myproject
# Open in VS Code → "Reopen in Container"
# Image is pulled (30 sec) instead of built (5 min)
```

### Implementation Details

**What the command does:**
1. Reads `.devcontainer/Dockerfile`
2. Builds the image with `docker build`
3. Tags as `{registry}/{name}:{tag}`
4. Pushes to registry (requires `docker login`)
5. Updates `devcontainer.json` to use `image` instead of `build`
6. Optionally commits the change

**Files affected:**
- `bin/spinbox` - New command routing
- `lib/publish.sh` - New library for publish functionality
- `.devcontainer/devcontainer.json` - Modified to use image

**Authentication:**
- Relies on existing `docker login` credentials
- No Spinbox-specific auth management
- Works with any Docker-compatible registry

### Considerations

**When to republish:**
- After changing Dockerfile
- After updating base image versions
- After adding new system dependencies

**Versioning strategy options:**
- `latest` - Always use newest (simple, but can break)
- Git SHA - `myorg/myproject-dev:abc123`
- Semantic version - `myorg/myproject-dev:1.2.0`
- Date-based - `myorg/myproject-dev:2024-01-15`

**Private registries:**
- Docker Hub (free tier: 1 private repo)
- GitHub Container Registry (ghcr.io)
- AWS ECR, Google GCR, Azure ACR
- Self-hosted registry

---

## Phase 2: Project Templates

### Problem Statement

Teams often want to:
- Start new projects from a proven structure
- Share organizational best practices
- Maintain consistency across projects
- Avoid copy-paste of boilerplate

### Proposed Solution

Allow exporting projects as templates and creating new projects from templates.

### New Commands

**Export template:**
```bash
spinbox export --template [OPTIONS] OUTPUT

OPTIONS:
    --exclude PATTERN      Exclude files matching pattern (can repeat)
    --include-git          Include .git directory (default: false)
    --include-env          Include .env files (default: false)

EXAMPLES:
    spinbox export --template ./my-template.tar.gz
    spinbox export --template --exclude "*.pyc" --exclude "__pycache__" ./starter.tar.gz
```

**Create from template:**
```bash
spinbox create PROJECT_NAME --from TEMPLATE [OPTIONS]

TEMPLATE can be:
    - Local path: ./templates/api-starter
    - Local archive: ./templates/api-starter.tar.gz
    - URL: https://github.com/org/templates/releases/download/v1/api.tar.gz
    - GitHub shorthand: github:org/repo/path (future)

EXAMPLES:
    spinbox create myapi --from ./templates/fastapi-starter
    spinbox create myapi --from https://example.com/templates/api.tar.gz
```

### Template Structure

A template is essentially a Spinbox project with:
- All standard project files
- Optional `template.json` manifest for metadata

**template.json (optional):**
```json
{
  "name": "FastAPI Starter",
  "description": "Production-ready FastAPI template with PostgreSQL",
  "version": "1.0.0",
  "author": "Your Org",
  "variables": {
    "PROJECT_NAME": {
      "description": "Name of the project",
      "default": "myproject"
    },
    "PYTHON_VERSION": {
      "description": "Python version to use",
      "default": "3.11"
    }
  }
}
```

### Template Processing

When creating from template:
1. Download/extract template
2. Read `template.json` if present
3. Replace placeholders in files:
   - `{{PROJECT_NAME}}` → actual project name
   - `{{PYTHON_VERSION}}` → configured version
4. Copy to destination
5. Initialize git (unless --no-git)

### Use Cases

**Company starter templates:**
```bash
# DevOps maintains approved templates
spinbox create new-service --from https://internal.company.com/templates/microservice.tar.gz
```

**Open source starters:**
```bash
# Community templates
spinbox create myapp --from https://github.com/spinbox-templates/fastapi-production/releases/latest/download/template.tar.gz
```

**Personal boilerplates:**
```bash
# Export your favorite setup
cd my-perfect-project
spinbox export --template ~/templates/my-stack.tar.gz

# Use it for new projects
spinbox create newproject --from ~/templates/my-stack.tar.gz
```

### Implementation Phases

**Phase 2a: Basic template support**
- Export as tar.gz
- Create from local path/archive
- Simple file copying (no variable substitution)

**Phase 2b: Remote templates**
- Download from URL
- Handle authentication for private URLs
- Cache downloaded templates

**Phase 2c: Template variables**
- Parse template.json
- Substitute variables in files
- Interactive prompts for missing variables

---

## Phase 3: GitHub Codespaces Integration (Future)

### Concept

GitHub Codespaces uses DevContainer spec, so Spinbox projects already work. Enhancement opportunities:

**Codespaces-specific optimizations:**
- Pre-build configuration
- Secrets integration
- Port forwarding setup

**New command:**
```bash
spinbox codespaces --setup
# Generates .devcontainer/devcontainer.json optimizations for Codespaces
```

---

## Alternative Approaches Considered

### 1. Spinbox Cloud Registry
**Idea:** Host a Spinbox-specific registry for sharing
**Rejected because:** Adds complexity, maintenance burden, lock-in

### 2. Docker Compose Profiles for Teams
**Idea:** Generate team-specific compose profiles
**Status:** Could complement other approaches, not a replacement

### 3. Nix/Devbox Integration
**Idea:** Use Nix for reproducible environments
**Deferred:** Different paradigm, could be future option

---

## Success Metrics

- Time to first development environment for new teammate
- Number of "it works on my machine" issues
- Team adoption of consistent tooling

---

## Open Questions

1. Should templates be versioned? How to handle template updates?
2. Should we maintain a curated template gallery?
3. How to handle secrets in templates (obviously exclude, but document)?
4. Should `spinbox publish` also push service images (PostgreSQL configs, etc.)?

---

## Related Documentation

- [Architecture](./architecture.md) - Overall system design
- [Deployment Roadmap](./roadmap-deployment.md) - Production deployment features
