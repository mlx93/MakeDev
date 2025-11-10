# Zero-to-Running Developer Environment
## Implementation Guide (For Sub-Agents)

**Version:** 2.0  
**Last Updated:** November 10, 2025  
**Purpose**: Concise implementation reference for sub-agents

---

## Document Hierarchy

**Source of Truth (Primary References):**
- `PRD_1_Product_v2.md` - Product requirements and user stories
- `PRD_2_Tech_Spec_v2.md` - Technical specifications and architecture
- `Demo_v2.md` - Demo script and expected flows

**This Document:**
- Minimal implementation structure and conventions
- File tree outlines (no code snippets)
- Key constraints and handoff points

---

## Repository Structure

### Repo A: zero-to-running-dev-env (Tool)

```
zero-to-running-dev-env/
├── README.md                    # USER_README.md content
├── Makefile                     # Core orchestration
├── config.yaml.example          # Configuration template
├── docker/
│   ├── docker-compose.yml
│   ├── Dockerfile.frontend
│   └── Dockerfile.backend
├── k8s/                         # Kubernetes manifests
│   ├── namespace.yaml
│   ├── frontend/ (deployment, service, configmap)
│   ├── backend/ (deployment, service, configmap, secret template)
│   ├── postgres/ (statefulset, service, pvc, secret template)
│   └── redis/ (deployment, service)
├── terraform/                   # GKE provisioning
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
├── scripts/
│   ├── check-prerequisites.sh   # Pre-flight checks
│   ├── setup-local.sh
│   ├── scaffold-project.sh      # Generate "hello world" projects (with pre-commit hooks + GitHub Actions)
│   ├── seed-database.ts         # Smart seed generator
│   ├── deploy-gke.sh
│   ├── health-check.sh
│   ├── cleanup.sh               # Teardown (with --keep-cluster)
│   └── env-to-k8s-secrets.sh   # .env.production → K8s Secrets
└── scaffold-templates/          # Code generation templates
    ├── frontend/
    └── backend/
```

### Repo B: example-task-app (Demo App)

```
example-task-app/
├── README.md
├── .env.example
├── frontend/                    # React + Vite + TS + Tailwind
│   ├── src/
│   │   ├── components/ (LoginForm, TaskList, TaskItem, TaskForm)
│   │   ├── pages/ (LoginPage, DashboardPage)
│   │   ├── context/ (AuthContext)
│   │   └── utils/ (api.ts)
│   └── package.json
└── backend/                     # Express + TS + Prisma
    ├── src/
    │   ├── routes/ (auth.ts, tasks.ts, health.ts)
    │   ├── middleware/ (auth.ts, errorHandler.ts)
    │   └── services/ (authService.ts, taskService.ts)
    ├── prisma/
    │   └── schema.prisma        # User + Task models
    └── package.json
```

---

## Core Conventions

### Ports (Fixed)
- Frontend: 3000
- Backend: 8080
- PostgreSQL: 5432
- Redis: 6379

### Project Structure (Convention)
- Frontend: `/frontend`
- Backend: `/backend`
- Prisma schema: `backend/prisma/schema.prisma`
- Environment: `.env` (or `.env.production` for GKE)

**Override**: All via `config.yaml` (convention over configuration)

### Makefile Targets (Required - Core Commands Only)

```makefile
dev        # Start local environment (Docker Compose) - P0 requirement
seed       # Generate fake data - P2 (promoted to core)
deploy     # Deploy to GKE - Core requirement
destroy    # Teardown all resources - P0 requirement
help       # Show all commands (optional, for discoverability)
```

**Note**: Keep it simple - only 4-5 core commands. Migrations auto-run on `make dev` startup. Other commands (status, logs, stop, clean) are not required by original PRD.

### config.yaml Schema (Minimal)

```yaml
project:
  name: string              # Required
  git_repo: string          # Optional (empty = scaffold)

services:
  frontend:
    path: ./frontend        # Optional override
    port: 3000              # Optional override
  backend:
    path: ./backend         # Optional override
    port: 8080              # Optional override
  database:
    schema_path: ./backend/prisma/schema.prisma
  cache:
    enabled: true           # Optional (tool supports Redis always)

gke:
  project_id: string       # REQUIRED
  region: us-central1       # Default
  cluster_name: string      # Auto-generated if empty

seed:
  users: 30                 # Default
  tasks_per_user: "5-10"    # Range or number
```

---

## Key Constraints

### Security
- Never log or print secret values
- Auto-detect sensitive keys (password, secret, key, token)
- `.env` in `.gitignore` always
- `.env.production` preferred for GKE (fallback to `.env`)

### Idempotency
- All `make` targets must be safe to run multiple times
- `make deploy` reuses existing cluster automatically
- `make seed` optionally clears existing data

### Error Handling
- **Keep error messages simple** - Clear, actionable, not verbose
- Port conflicts: Simple error message, suggest changing config.yaml
- GKE quota: Simple error message with quota link
- Missing tools: One-line install command (macOS: `brew install ...`)

### Pre-Flight Checks
- `make dev`: Check Docker, Node.js
- `make deploy`: Check gcloud, kubectl, Terraform
- Prompt for gcloud auth if not authenticated

### Health Checks
- All services expose `/health` endpoint
- Backend also exposes `/health/ready` (K8s readiness)
- Response format: `{status: "ok"}` (simple JSON)
- Startup waits for all health checks before "ready"

---

## Technology Stack (Pinned Versions)

**Tool Dependencies:**
- Node.js: 20.x LTS (exact version in package.json)
- Docker: 24.0+ (check version, provide install command)
- gcloud: Latest (check version, provide install command)
- kubectl: 1.28+ (check version, provide install command)
- Terraform: 1.6.0+ (check version, provide install command)

**Application Stack:**
- Frontend: React 18.2, Vite 5.0, TypeScript 5.3, Tailwind CSS 3.4
- Backend: Node.js 20 LTS, Express 4.18, TypeScript 5.3, Prisma 5.7
- Database: PostgreSQL 16
- Cache: Redis 7.2

**Note**: Pin exact versions in package.json (no ranges like `^5.0.0`)

---

## Platform Constraints

- **macOS only** (primary platform)
- Docker Desktop required (not Docker Engine)
- GCP project must already exist (user provides project_id)
- Artifact Registry (not legacy GCR)

---

## Handoff Points

### DXS → C&C Part 1
- File trees defined
- Makefile stubs in place
- config.yaml schema defined
- Ports and URLs agreed (3000, 8080, 5432, 6379)
- Health endpoint contracts (`/health`, `/health/ready`)
- Scaffolding system designed (pre-commit hooks + GitHub Actions templates)

### C&C Part 1 → A&D
- Docker Compose working
- Dockerfiles created (dev stage)
- `make dev` works end-to-end
- Hot reload configured

### A&D → ETA
- Tool's backend API working locally (health endpoints, status endpoints)
- Tool's frontend working locally (if any UI needed)
- Seed generator working (reads Prisma schema)
- Health checks implemented (`{status: "ok"}`)
- Migrations auto-run on `make dev` startup

### ETA → C&C Part 2
- Example-task-app repo complete
- Works with `make dev` locally
- Simple task CRUD functional

### C&C Part 2 → D&D
- `make dev` works end-to-end
- `make deploy` works end-to-end
- `make destroy` works end-to-end
- All services healthy in local and GKE

---

## Implementation Phases

### Phase 1: Core Local Dev
- Makefile + docker-compose.yml
- Dockerfiles (dev stage)
- Health checks
- Pre-flight checks

### Phase 2: GKE Deployment
- Terraform (GKE cluster)
- K8s manifests (all services)
- deploy-gke.sh
- cleanup.sh

### Phase 3: Advanced Features
- Seed generator (seed-database.ts)
- Project scaffolding (scaffold-project.sh - generates "hello world" level project with pre-commit hooks + GitHub Actions)
- Tool's backend/frontend (health checks, status endpoints) - built by A&D agent
- Example task app (separate repo - full task CRUD app, built by ETA agent)

### Phase 4: Polish & Docs
- Finalize SETUP_INSTRUCTIONS.md
- Update READMEs
- Demo runbook

---

## Deliverable Hygiene

- **No long code snippets** in planning docs
- **File trees + minimal stubs** only
- **Generate code** only where ambiguity would block next agent
- **DONE.md** per agent (only when approved)
- **Assumptions documented** in DONE.md
- **Next handoff steps** clearly stated

---

## Key Design Decisions

1. **Convention over Configuration**: Default paths, override via config.yaml
2. **Docker Compose locally, K8s for GKE**: Near-perfect parity
3. **Multi-stage Dockerfiles**: Dev (hot reload) + Production (optimized)
4. **Backend internal only**: ClusterIP service, frontend calls via K8s DNS
5. **Cluster reuse**: Automatic detection and reuse
6. **Redis support**: Tool always supports it, user can disable in their project

---

**Reference**: Always refer to PRD_1_Product_v2.md and PRD_2_Tech_Spec_v2.md as primary sources. This guide provides minimal structure only.

