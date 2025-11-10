# Sub-Agent Execution Flow

**Version:** 1.0  
**Last Updated:** November 10, 2025  
**Purpose**: Execution order and phase alignment for sub-agents

---

## Execution Order

Agents execute in this sequence to align with implementation phases:

```
DXS → C&C Part 1 → A&D → ETA → C&C Part 2 → D&D
```

### Why This Order?

1. **DXS** provides structure first (file trees, Makefile stubs, config schema)
2. **C&C Part 1** gets local dev working (Docker Compose, `make dev`)
3. **A&D** builds the tool's application (needs working local dev environment)
4. **ETA** builds example-task-app repo (needs tool's tech stack defined)
5. **C&C Part 2** adds deployment (needs working applications)
6. **D&D** documents everything (needs everything working)

---

## Phase Alignment

| Phase | Agent(s) | Focus | Deliverables |
|-------|----------|-------|--------------|
| **Phase 1: Core Local Dev** | DXS + C&C Part 1 | Get `make dev` working | File trees, Docker Compose, `make dev` functional |
| **Phase 2: GKE Deployment** | C&C Part 2 | Get `make deploy` working | Terraform, K8s manifests, `make deploy` functional |
| **Phase 3: Advanced Features** | A&D + ETA | Build tool app + example app | Tool's backend/frontend, example-task-app repo |
| **Phase 4: Polish & Docs** | D&D | Documentation | READMEs, troubleshooting, demo runbook |

---

## Detailed Flow

### Step 1: DXS (Dev Experience & Scaffolder)
**Duration**: ~4-6 hours  
**Inputs**: PRD_1, PRD_2, IMPLEMENTATION_GUIDE  
**Outputs**: 
- File trees for both repos
- Makefile stubs
- config.yaml.example
- Health check contracts (`{status: "ok"}`)
- Project scaffolding design (generates "hello world" level project)
- Pre-commit hooks setup (Husky + lint-staged) in scaffolding templates
- GitHub Actions workflow template (`.github/workflows/lint.yml`) in scaffolding templates

**Gate**: File trees, Makefile structure, config schema approved, scaffolding system designed

---

### Step 2: C&C Part 1 (Local Dev Infrastructure)
**Duration**: ~8-10 hours  
**Inputs**: DXS outputs, PRD_1, PRD_2, IMPLEMENTATION_GUIDE  
**Outputs**:
- docker-compose.yml (working)
- Dockerfile.frontend (dev stage)
- Dockerfile.backend (dev stage)
- scripts/check-prerequisites.sh
- scripts/health-check.sh
- scripts/setup-local.sh
- `make dev` wired and working

**Gate**: `make dev` works, all services healthy locally, hot reload working

---

### Step 3: A&D (App & Data)
**Duration**: ~8-12 hours  
**Inputs**: DXS outputs, C&C Part 1 outputs, PRD_1, PRD_2  
**Outputs**:
- Tool's backend API (Express + Prisma) - for health checks, status, etc.
- Tool's frontend app (React + Vite) - if any UI needed
- Seed generator (seed-database.ts) - reads Prisma schema
- Health endpoints (`/health`, `/health/ready`)

**Gate**: Tool's backend/frontend working locally, seed generator working, health checks implemented

---

### Step 4: ETA (Example Task App)
**Duration**: ~6-8 hours  
**Inputs**: DXS outputs, A&D outputs, PRD_1, PRD_2  
**Outputs**:
- Complete `example-task-app/` repository
- Backend API (Express + Prisma) - simple task CRUD
- Frontend app (React + Vite) - login, dashboard, task list/form
- Seed generator (seed-database.ts) - users and tasks
- Health endpoints (`/health`, `/health/ready`)

**Gate**: Example-task-app repo complete, works with `make dev` locally

---

### Step 5: C&C Part 2 (GKE Deployment Infrastructure)
**Duration**: ~10-12 hours  
**Inputs**: DXS outputs, A&D outputs, ETA outputs, PRD_1, PRD_2  
**Outputs**:
- Terraform configuration (GKE cluster)
- K8s manifests (all services)
- scripts/deploy-gke.sh
- scripts/env-to-k8s-secrets.sh
- scripts/cleanup.sh
- `make deploy` wired and working
- `make destroy` wired and working

**Gate**: `make deploy` works, `make destroy` works, all services healthy in GKE

---

### Step 6: D&D (Docs & Demo)
**Duration**: ~6-8 hours  
**Inputs**: All previous outputs, Demo_v2.md  
**Outputs**:
- Finalized SETUP_INSTRUCTIONS.md
- Updated READMEs
- DEMO_RUNBOOK.md
- TROUBLESHOOTING.md
- Golden outputs documented

**Gate**: All documentation finalized, demo verified

---

## Quality Gates

Each gate must be approved before proceeding to next agent.

### Gate 1: DXS Complete
- ✅ File trees approved
- ✅ Makefile structure approved
- ✅ config.yaml schema approved
- ✅ Health check contracts defined (`{status: "ok"}`)
- ✅ Scaffolding system designed (pre-commit hooks + GitHub Actions templates)

### Gate 2: C&C Part 1 Complete
- ✅ Docker Compose working
- ✅ `make dev` works end-to-end
- ✅ All services healthy locally
- ✅ Hot reload working

### Gate 3: A&D Complete
- ✅ Tool's backend API working locally
- ✅ Tool's frontend working locally (if any)
- ✅ Seed generator working
- ✅ Health checks implemented

### Gate 4: ETA Complete
- ✅ Example-task-app repo complete
- ✅ Works with `make dev` locally
- ✅ Simple task CRUD functional

### Gate 5: C&C Part 2 Complete
- ✅ `make deploy` works end-to-end
- ✅ `make destroy` works end-to-end
- ✅ All services healthy in GKE

### Gate 6: D&D Complete
- ✅ All documentation finalized
- ✅ Demo runbook verified

---

## Key Clarifications (From User)

### Health Check Schema
- Response format: `{status: "ok"}` (simple JSON)
- No complex schemas needed

### Error Messages
- Keep simple - clear, actionable, not verbose
- Port conflicts: Simple message + suggest config.yaml change
- GKE quota: Simple message + quota link

### Demo Credentials
- Users generated via seed (not hardcoded)
- Exception: Example task-app can have 1 hardcoded demo user (demo@example.com) for demo purposes
- Make functions should only supply seeded users

### Scaffolding Scope
- Scaffolding generates "hello world" level project (basic structure), NOT full task app
- Full task app is built separately by ETA agent as example-task-app repo
- Scaffolding includes pre-commit hooks (Husky + lint-staged) and GitHub Actions workflow

### Migrations
- Migrations auto-run on `make dev` startup (no separate `make migrate` command needed)

---

## Handoff Information

Each agent's DONE.md should include:
- Assumptions made
- Artifacts created
- Next handoff steps clearly stated
- Any blockers or questions

---

**This flow ensures local dev works before building app, and app works before deployment.**

