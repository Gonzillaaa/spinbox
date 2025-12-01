# Manual Testing Guide: Component Combinations

This directory contains scripts for manually testing Spinbox component combinations.

## Overview

Spinbox has **8 components** that can be combined in various ways, plus **6 profiles** for common setups. This guide organizes 40 key test scenarios into 4 priority levels.

## Components

| Component | Flag | Category |
|-----------|------|----------|
| Python | `--python` | Base runtime |
| Node.js | `--node` | Base runtime |
| FastAPI | `--fastapi` | Framework |
| Next.js | `--nextjs` | Framework |
| PostgreSQL | `--postgresql` | Database |
| MongoDB | `--mongodb` | Database |
| Redis | `--redis` | Cache |
| Chroma | `--chroma` | Vector DB |

## Profiles

| Profile | Components |
|---------|------------|
| `python` | Python |
| `node` | Node.js |
| `web-app` | Python + FastAPI + Next.js + PostgreSQL |
| `api-only` | Python + FastAPI + PostgreSQL + Redis |
| `data-science` | Python (with data-science requirements) |
| `ai-llm` | Python + Chroma |

## Test Scripts

| Script | Priority | Tests | Description |
|--------|----------|-------|-------------|
| `priority-1-critical.sh` | P1 | 12 | Base runtimes, profiles, single DB |
| `priority-2-common.sh` | P2 | 12 | Frameworks + databases, full-stack |
| `priority-3-edge-cases.sh` | P3 | 10 | Multi-DB, advanced combinations |
| `priority-4-versions.sh` | P4 | 6 | Version override flags |

## Usage

### Run All Tests (Dry-Run)
```bash
# Quick validation - no files created
./priority-1-critical.sh --dry-run
./priority-2-common.sh --dry-run
./priority-3-edge-cases.sh --dry-run
./priority-4-versions.sh --dry-run
```

### Run All Tests (Full)
```bash
# Creates actual projects in /tmp
./priority-1-critical.sh
./priority-2-common.sh
./priority-3-edge-cases.sh
./priority-4-versions.sh
```

### Run Single Priority
```bash
cd testing/manual
./priority-1-critical.sh          # Full test
./priority-1-critical.sh --dry-run # Dry-run only
```

## Validation Checklist

For each test, verify:

### 1. Project Creation
- [ ] Project directory created
- [ ] `.devcontainer/` exists
- [ ] `devcontainer.json` is valid JSON
- [ ] `docker-compose.yml` is valid (if services selected)

### 2. Version Configuration Output
- [ ] Shows correct versions for all selected components
- [ ] Source shows correctly (CLI flag / config / default)

### 3. Connection Details Output
- [ ] PostgreSQL connection info (if selected)
- [ ] MongoDB connection info (if selected)
- [ ] Redis connection info (if selected)
- [ ] Chroma connection info (if selected)

### 4. README.md
- [ ] Services section lists all selected services
- [ ] Connection details match terminal output

### 5. DevContainer Launch (optional)
- [ ] Container builds successfully
- [ ] All services start
- [ ] Connections work from within container

## Test Coverage Summary

| Priority | Scenarios | Description |
|----------|-----------|-------------|
| P1 | 12 | Critical path - most common scenarios |
| P2 | 12 | Common combinations - realistic use cases |
| P3 | 10 | Edge cases - less common but valid |
| P4 | 6 | Version overrides |
| **Total** | **40** | ~16% of all possible combinations |

## Cleanup

After testing, clean up test projects:
```bash
rm -rf /tmp/test-*
```
