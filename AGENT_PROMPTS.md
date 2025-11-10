# Zero-to-Running Developer Environment
## Sub-Agent Prompts & Delegation Strategy

**Version:** 1.0  
**Last Updated:** November 10, 2025

---

## Agent Structure

Five specialized agents, executed in this order to align with implementation phases:

1. **DXS** (Dev Experience & Scaffolder) - Planning & Structure
2. **C&C** (Containers & Cloud) - Part 1: Local Dev Infrastructure
3. **A&D** (App & Data) - Application Implementation (Tool's backend/frontend)
4. **ETA** (Example Task App) - Example Project Repository (Separate repo)
5. **C&C** (Containers & Cloud) - Part 2: GKE Deployment Infrastructure
6. **D&D** (Docs & Demo) - Documentation & Polish

**Note**: C&C is split into two parts to align with phases (local dev first, then deployment). ETA builds a separate example-task-app repo that demonstrates the tool's capabilities.

---

## Global Constraints (All Agents)

- **Primary References**: `PRD_1_Product_v2.md` and `PRD_2_Tech_Spec_v2.md` are source of truth
- **Secondary Reference**: `IMPLEMENTATION_GUIDE.md` for structure/conventions
- **No long code snippets** in planning - use file trees + minimal stubs
- **Conventions over configuration** - defaults, override via config.yaml
- **Idempotent operations** - all make targets safe to run multiple times
- **Never log secrets** - auto-detect sensitive keys, never print
- **macOS only** - primary platform
- **Pin dependency versions** - exact versions in package.json (no ranges)

---

# Agent 1: DXS (Dev Experience & Scaffolder)

## Charter

Plan and scaffold both repositories: `zero-to-running-dev-env` (tool) and `example-task-app` (demo app). Own Makefile targets, config.yaml schema, repository trees, and developer experience guardrails. **Also design project scaffolding system** - when user runs `make dev` with empty `git_repo`, tool generates complete React + Node.js project (see PRD_1, US-006).

## Inputs

- `PRD_1_Product_v2.md` - Product requirements
- `PRD_2_Tech_Spec_v2.md` - Technical specifications
- `IMPLEMENTATION_GUIDE.md` - Implementation structure

## Tasks

1. **Design Makefile Structure**
   - Define core targets only: `dev`, `seed`, `deploy`, `destroy`, `help` (4-5 commands total)
   - Create minimal stubs (no implementation, just structure)
   - Ensure idempotency and clear error messages
   - **Note**: Migrations auto-run on `make dev` startup (no separate `make migrate` needed)
   - **Note**: Other commands (status, logs, stop, clean) are not required by original PRD - keep it simple

2. **Design config.yaml Schema**
   - Define all configuration options
   - Document defaults and overrides
   - Create `config.yaml.example` template
   - Note: `git_repo` empty string triggers project scaffolding (see PRD_1, US-006)

3. **Design Repository Trees**
   - `zero-to-running-dev-env/` - Complete file tree (no code)
   - `example-task-app/` - Complete file tree (no code)
   - Reference `IMPLEMENTATION_GUIDE.md` for structure
   - Include `scaffold-templates/` directory structure (for empty repo generation)

4. **Define Ports & URLs**
   - Frontend: 3000
   - Backend: 8080
   - PostgreSQL: 5432
   - Redis: 6379
   - Document all URLs (local and GKE)

5. **Create README Stubs**
   - `zero-to-running-dev-env/README.md` (use `USER_README.md` content)
   - `example-task-app/README.md` (minimal)

6. **Define Health Check Contracts**
   - `/health` endpoint for all services
   - `/health/ready` for backend (K8s readiness)
   - Response format: `{status: "ok"}` (simple JSON schema)

7. **Design Project Scaffolding System**
   - Plan `scaffold-project.sh` script structure
   - Design template system (`scaffold-templates/` directory)
   - Define what gets generated when `git_repo` is empty
   - **Scope**: Generate "hello world" level project (basic structure, not full task app)
   - Include pre-commit hooks (Husky + lint-staged) for ESLint
   - Include GitHub Actions workflow (`.github/workflows/lint.yml`) for linting on PRs
   - Reference PRD_1, US-006 (empty repository scaffolding)

8. **Create 10-Step First Run Checklists**
   - One for tool repo (developer setup)
   - One for example app (end user setup)

## Outputs

- File trees for both repos (text format, no code)
- Makefile stub (targets defined, minimal implementation)
- `config.yaml.example` (complete schema with comments)
- README stubs (structure only, minimal content)
- Port/URL documentation
- Health check contract documentation
- Project scaffolding system design (script structure, template organization)
- Pre-commit hooks setup (Husky + lint-staged) in scaffolding templates
- GitHub Actions workflow template (`.github/workflows/lint.yml`) in scaffolding templates
- First run checklists (10 steps each)

## Constraints

- **No code implementation** - only structure and stubs
- **Reference PRDs** - all decisions must align with PRD_1 and PRD_2
- **Minimal stubs** - just enough to unblock next agent
- **Convention-first** - defaults for everything, overrides optional

## Handoff to A&D

- File trees approved
- Makefile structure approved
- config.yaml schema approved
- Ports/URLs agreed
- Health check contracts defined

## Deliverable

**DONE.md** (only when approved) containing:
- Assumptions made
- Artifacts created (file trees, stubs, schemas)
- Next handoff steps for A&D
- Any blockers or questions

---

# Agent 2: A&D (App & Data)

## Charter

Implement minimal backend (Express/TypeScript/Prisma), frontend (React/Vite/TypeScript/Tailwind), and the seed generator that reads Prisma schema for the **tool itself**. Ensure hot module replacement (HMR) works in Docker.

**Note**: This agent runs AFTER C&C Part 1 (local dev infrastructure is already working). This builds the tool's own backend/frontend (for health checks, status, etc.), NOT the example-task-app repo (that's built by ETA agent).

## Inputs

- `PRD_1_Product_v2.md` - Product requirements (especially US-001 through US-011)
- `PRD_2_Tech_Spec_v2.md` - Technical specifications (sections 3-5)
- `IMPLEMENTATION_GUIDE.md` - Structure and conventions
- DXS outputs: File trees, Makefile stubs, config.yaml schema, health check contracts
- C&C Part 1 outputs: Docker Compose, Dockerfiles, `make dev` working

## Tasks

1. **Implement Prisma Schema**
   - User model (id, email, name, password, timestamps)
   - Task model (id, title, description, status, priority, dueDate, userId, timestamps)
   - Enums: TaskStatus (TODO, IN_PROGRESS, DONE, ARCHIVED), Priority (LOW, MEDIUM, HIGH, URGENT)
   - Relations: User → Tasks (one-to-many)
   - Initial migration

2. **Implement Backend API**
   - Express app setup (TypeScript)
   - Auth routes: `POST /auth/register`, `POST /auth/login`, `GET /auth/me`
   - Task routes: `GET /tasks`, `GET /tasks/:id`, `POST /tasks`, `PATCH /tasks/:id`, `DELETE /tasks/:id`
   - Health routes: `GET /health`, `GET /health/ready` (returns `{status: "ok"}`)
   - Middleware: JWT auth, error handler, request validation (Zod)
   - Services: authService (bcrypt + JWT), taskService (Prisma CRUD)
   - **Note**: Migrations auto-run on `make dev` startup (no separate `make migrate` command needed)

3. **Implement Frontend**
   - React + Vite + TypeScript + Tailwind CSS
   - Components: LoginForm, TaskList, TaskItem, TaskForm, TaskFilter
   - Pages: LoginPage, DashboardPage
   - Context: AuthContext (JWT storage)
   - Utils: api.ts (Axios with interceptors)
   - Routing: React Router

4. **Implement Seed Generator**
   - `scripts/seed-database.ts` (TypeScript)
   - Reads Prisma schema (introspection)
   - Uses Faker.js for realistic data
   - Generates users and tasks (respects relationships)
   - Configurable via config.yaml (users count, tasks per user)
   - **Note**: Users should be generated via seed (not hardcoded)
   - Deployed app to GKE also needs seeded users
   - Exception: Example task-app can have 1 hardcoded demo user (demo@example.com) for demo purposes, but make functions should only supply seeded users

5. **Ensure HMR Works**
   - Frontend: Vite HMR configured
   - Backend: tsx watch configured
   - Docker volume mounts for source code
   - Verify hot reload in containers

6. **Implement Health Checks**
   - Backend: `/health` (service status), `/health/ready` (dependencies ready)
   - Frontend: Basic health endpoint (optional)
   - Database connectivity check
   - Redis connectivity check (if enabled)

## Outputs

- Complete Prisma schema + migrations
- Backend API (all routes, middleware, services)
- Frontend app (all components, pages, routing)
- Seed generator (`seed-database.ts`)
- Health endpoints implemented
- HMR verified working

## Constraints

- **Follow DXS structure** - use file trees and ports defined by DXS
- **Reference PRDs** - all features must match PRD_1 and PRD_2 requirements
- **Minimal but functional** - working CRUD, not polished UI
- **Health checks required** - must match contracts from DXS
- **Pin versions** - exact versions in package.json

## Handoff to ETA

- Tool's backend API working locally (health endpoints, status endpoints)
- Tool's frontend working locally (if any UI needed for tool)
- Seed generator working (generates realistic data from Prisma schema)
- Health checks implemented and tested (`{status: "ok"}` format)
- HMR verified in Docker

**Note**: ETA agent will build the separate example-task-app repo using the same tech stack.

## Deliverable

**DONE.md** (only when approved) containing:
- Assumptions made
- Artifacts created (code files, schemas)
- Testing notes (what works, what's tested)
- Next handoff steps for ETA
- Any blockers or questions

---

# Agent 4: ETA (Example Task App)

## Charter

Build a separate `example-task-app` repository that demonstrates the tool's capabilities. This is a complete, functional task list application that developers can clone as an example of an existing project. Keep it simple - just a basic task CRUD app.

**Note**: This agent runs AFTER A&D (tool's tech stack is defined). This builds a separate repo that works with the tool's `make dev` and `make deploy` commands.

## Inputs

- `PRD_1_Product_v2.md` - Product requirements (especially US-006, US-007, US-008)
- `PRD_2_Tech_Spec_v2.md` - Technical specifications (sections 3-5)
- `IMPLEMENTATION_GUIDE.md` - Structure and conventions
- DXS outputs: File trees, Makefile structure, config.yaml schema
- A&D outputs: Tech stack confirmed (Express, React, Prisma, etc.)

## Tasks

1. **Create Example Task App Repository Structure**
   - Separate repo: `example-task-app/`
   - Same tech stack as tool: React + Vite + TypeScript + Tailwind, Express + TypeScript + Prisma
   - Works with tool's `make dev` and `make deploy` commands

2. **Implement Backend (Express + Prisma)**
   - Auth routes: `POST /auth/login`, `GET /auth/me` (no registration - use seeded users)
   - Task routes: `GET /tasks`, `GET /tasks/:id`, `POST /tasks`, `PATCH /tasks/:id`, `DELETE /tasks/:id`
   - Health routes: `GET /health`, `GET /health/ready` (returns `{status: "ok"}`)
   - Prisma schema: User and Task models (simple - id, title, description, status, userId, timestamps)
   - JWT auth middleware, error handling

3. **Implement Frontend (React + Vite)**
   - Login page (use seeded users)
   - Dashboard with task list
   - Task form (create/edit)
   - Simple UI with Tailwind CSS
   - Auth state management

4. **Create Seed Data**
   - `seed-database.ts` script
   - Generates users and tasks using Faker.js
   - Works with `make seed` command

5. **Ensure Compatibility**
   - Works with tool's `make dev` command (Docker Compose)
   - Works with tool's `make deploy` command (GKE)
   - Uses same ports (3000 frontend, 8080 backend)
   - Uses same health check format

## Outputs

- Complete `example-task-app/` repository
- Backend API (Express + Prisma)
- Frontend app (React + Vite)
- Seed generator (`seed-database.ts`)
- Health endpoints (`/health`, `/health/ready`)
- README.md for example app

## Constraints

- **Keep it simple** - Basic task CRUD, no complex features
- **Use same tech stack** - Must work with tool's make commands
- **Seeded users only** - No registration endpoint (use `make seed`)
- **Exception**: Can have 1 hardcoded demo user (demo@example.com) for demo purposes

## Handoff to C&C Part 2

- Example-task-app repo complete and functional
- Works with `make dev` locally
- Ready to be deployed with `make deploy`

---

# Agent 5: C&C (Containers & Cloud)

## Charter

Containerize applications, compose locally with Docker Compose, and deploy to GKE (Kubernetes manifests + Terraform). Handle Secrets/ConfigMaps, image push to Artifact Registry, LoadBalancer URL, teardown safety, and cost notes.

**Note**: This agent is split into two parts:
- **Part 1** (runs after DXS): Docker Compose, Dockerfiles, `make dev` working
- **Part 2** (runs after A&D): Terraform, K8s manifests, `make deploy` working

## Inputs

**Part 1 Inputs:**
- `PRD_1_Product_v2.md` - Product requirements (especially US-001, FR-001, FR-006, FR-007)
- `PRD_2_Tech_Spec_v2.md` - Technical specifications (sections 6-7)
- `IMPLEMENTATION_GUIDE.md` - Structure and conventions
- DXS outputs: File trees, Makefile structure, config.yaml schema

**Part 2 Inputs:**
- `PRD_1_Product_v2.md` - Product requirements (especially US-012, US-013, US-014)
- `PRD_2_Tech_Spec_v2.md` - Technical specifications (sections 8-9)
- `IMPLEMENTATION_GUIDE.md` - Structure and conventions
- DXS outputs: File trees, Makefile structure, config.yaml schema
- A&D outputs: Tool's backend API, frontend app, health checks
- ETA outputs: Example-task-app repo (for testing deployment)

## Tasks

1. **Create Docker Compose**
   - Services: frontend, backend, postgres, redis
   - Health checks for all services
   - Dependency ordering (backend waits for DB, frontend waits for backend)
   - Volume mounts for HMR (source code)
   - Anonymous volumes for node_modules
   - Network configuration

2. **Create Dockerfiles**
   - `Dockerfile.frontend` - Multi-stage (dev + production)
   - `Dockerfile.backend` - Multi-stage (dev + production)
   - Dev stage: Hot reload (Vite HMR, tsx watch)
   - Production stage: Optimized builds

3. **Create Pre-Flight Checks**
   - `scripts/check-prerequisites.sh`
   - Check Docker, Node.js (for `make dev`)
   - Check gcloud, kubectl, Terraform (for `make deploy`)
   - Provide one-line install commands if missing

4. **Create Kubernetes Manifests**
   - Namespace
   - Frontend: Deployment (2 replicas), Service (LoadBalancer), ConfigMap
   - Backend: Deployment (2 replicas), Service (ClusterIP), ConfigMap, Secret template
   - PostgreSQL: StatefulSet (1 replica), Service (ClusterIP), PVC (10Gi), Secret template
   - Redis: Deployment (1 replica), Service (ClusterIP)
   - Health probes (liveness, readiness)
   - Resource limits

**Part 2: GKE Deployment Infrastructure** (runs after A&D)

5. **Create Terraform Configuration**
   - GKE cluster provisioning
   - Node pool (e2-medium x2, default)
   - Variables (project_id, region, cluster_name, etc.)
   - Outputs (cluster endpoint, CA cert)
   - Provider configuration
   - **Note**: Terraform state should be stored in GitHub (version controlled, not remote backend)

6. **Create Deployment Scripts**
   - `scripts/deploy-gke.sh` - Full deployment orchestration
     - Check prerequisites
     - Authenticate with GCP (prompt if needed)
     - Check for existing cluster (reuse if exists)
     - Provision cluster via Terraform (if needed)
     - Build and push images to Artifact Registry
     - Convert .env.production → K8s Secrets (fallback to .env)
     - Apply K8s manifests
     - Wait for pods ready
     - Display LoadBalancer IP and cost estimate
   - `scripts/env-to-k8s-secrets.sh` - Convert .env to K8s Secrets
     - Auto-detect sensitive keys
     - Generate Secret manifests

7. **Create Teardown Scripts**
   - `scripts/cleanup.sh` - Teardown resources
     - `make destroy` - Destroy everything (cluster + app) - P0 requirement
   - Cost warnings and confirmations
   - **Note**: `destroy-keep-cluster` is optional enhancement, not required by original PRD

8. **Wire Makefile Targets**
   - `make dev` - Run docker-compose up (with pre-flight checks)
   - `make seed` - Run seed-database.ts (generates fake data)
   - `make deploy` - Run deploy-gke.sh (with pre-flight checks for gcloud/kubectl/terraform)
   - `make destroy` - Run cleanup.sh (destroys everything by default)
   - `make help` - Show all commands
   - **Note**: Only implement core commands (dev, seed, deploy, destroy, help). Other commands not required.

9. **Error Handling**
   - **Keep error messages simple** - Clear, actionable, not verbose
   - Port conflicts: Simple error message, suggest config.yaml change
   - GKE quota: Simple error message with quota link
   - Missing tools: One-line install commands

## Outputs

**Part 1 Outputs:**
- `docker-compose.yml` (working, all services)
- `Dockerfile.frontend` and `Dockerfile.backend` (dev stage for hot reload)
- `scripts/check-prerequisites.sh` (pre-flight checks)
- `scripts/health-check.sh` (service health verification)
- `scripts/setup-local.sh` (local environment setup)
- `make dev` wired and working

**Part 2 Outputs:**
- All K8s manifests (deployments, services, statefulsets, secrets)
- Terraform configuration (cluster + node pool)
- `scripts/deploy-gke.sh` (deployment orchestration)
- `scripts/env-to-k8s-secrets.sh` (secret conversion)
- `scripts/cleanup.sh` (teardown)
- `make deploy` and `make destroy` wired and working

## Constraints

- **Follow DXS structure** - use file trees and ports
- **Reference PRDs** - all deployment must match PRD_1 and PRD_2
- **Backend internal only** - ClusterIP service, not LoadBalancer
- **Cluster reuse** - Automatic detection and reuse
- **Secrets handling** - .env.production preferred, fallback to .env
- **Never log secrets** - Auto-detect sensitive keys, never print

## Handoff Points

**After Part 1 (Local Dev):**
- `make dev` works end-to-end (all services healthy locally)
- Hot reload working
- Health checks pass locally

**After Part 2 (GKE Deployment):**
- `make deploy` works end-to-end (deploys to GKE, public URL)
- `make destroy` works end-to-end (clean teardown)
- All health checks pass in GKE

## Handoff to D&D

- `make dev` works end-to-end (all services healthy)
- `make deploy` works end-to-end (deploys to GKE, public URL)
- `make destroy` works end-to-end (clean teardown)
- All health checks pass in local and GKE
- Cost estimates displayed

## Deliverable

**DONE.md** (only when approved) containing:
- Assumptions made
- Artifacts created (Dockerfiles, K8s manifests, Terraform, scripts)
- Testing notes (what works locally, what works in GKE)
- Cost estimates
- Next handoff steps for D&D
- Any blockers or questions

---

# Agent 4: D&D (Docs & Demo)

## Charter

Finalize `SETUP_INSTRUCTIONS.md`, tighten repository READMEs, align with Demo v2 timing, capture "golden outputs" (expected command outputs), and add troubleshooting guide.

## Inputs

- `PRD_1_Product_v2.md` - Product requirements
- `PRD_2_Tech_Spec_v2.md` - Technical specifications
- `Demo_v2.md` - Demo script and expected flows
- `SETUP_INSTRUCTIONS.md` - Current setup guide (for tool developers)
- DXS outputs: README stubs, first run checklists
- A&D outputs: Tool's working application
- ETA outputs: Example-task-app repo
- C&C outputs: Working deployment

## Tasks

1. **Finalize SETUP_INSTRUCTIONS.md**
   - Keep concise (high-level summary)
   - macOS only
   - One-line install commands
   - Quick verification checklist
   - Clarify: This is for tool developers, not end users

2. **Update Tool README**
   - Use `USER_README.md` content
   - Ensure all make commands documented
   - Add troubleshooting basics
   - Add cost estimates

3. **Update Example App README**
   - Quick start guide
   - Demo credentials
   - Testing instructions

4. **Create Demo Runbook**
   - `DEMO_RUNBOOK.md` - Copy-paste commands
   - Expected outputs for each step
   - Fallback steps if something fails
   - Timing notes (6-minute demo target)

5. **Create Troubleshooting Guide**
   - Common issues and solutions
   - Port conflicts
   - Docker issues
   - GKE quota errors
   - Health check failures

6. **Capture Golden Outputs**
   - Expected `make dev` output
   - Expected `make seed` output
   - Expected `make deploy` output
   - Expected `make destroy` output
   - Health check responses (`{status: "ok"}`)

7. **Verify Demo Script Alignment**
   - Ensure demo script from Demo_v2.md works
   - Test all commands
   - Verify timing (6 minutes target)

## Outputs

- Finalized `SETUP_INSTRUCTIONS.md` (concise, tool developer focused)
- Updated `zero-to-running-dev-env/README.md` (end user focused)
- Updated `example-task-app/README.md`
- `DEMO_RUNBOOK.md` (copy-paste demo guide)
- `TROUBLESHOOTING.md` (common issues)
- Golden outputs documented

## Constraints

- **Reference PRDs** - All docs must align with PRD_1 and PRD_2
- **Reference Demo_v2** - Demo runbook must match demo script
- **Keep concise** - No long explanations, actionable steps only
- **Copy-paste ready** - Commands should be copy-pastable

## Final Deliverable

**DONE.md** (only when approved) containing:
- Assumptions made
- Artifacts created (all documentation)
- Demo verification notes
- Any remaining issues or future enhancements

---

## Phase Gates & Execution Order

### Gate 1: DXS Complete (Phase 1 Prep)
- ✅ File trees approved
- ✅ Makefile structure approved
- ✅ config.yaml schema approved
- ✅ Health check contracts defined

### Gate 2: C&C Part 1 Complete (Phase 1: Core Local Dev)
- ✅ Docker Compose working
- ✅ Dockerfiles created (dev stage)
- ✅ `make dev` works end-to-end
- ✅ All services healthy locally
- ✅ Hot reload working
- ✅ Health checks pass locally

### Gate 3: A&D Complete (Phase 3: Advanced Features)
- ✅ Tool's backend API working locally
- ✅ Tool's frontend working locally (if any)
- ✅ Seed generator working
- ✅ Health checks implemented
- ✅ HMR verified

### Gate 4: ETA Complete (Example Task App)
- ✅ Example-task-app repo complete
- ✅ Works with `make dev` locally
- ✅ Simple task CRUD functional

### Gate 5: C&C Part 2 Complete (Phase 2: GKE Deployment)
- ✅ Terraform configuration working
- ✅ K8s manifests created
- ✅ `make deploy` works end-to-end
- ✅ `make destroy` works end-to-end
- ✅ All services healthy in GKE

### Gate 6: D&D Complete (Phase 4: Polish & Docs)
- ✅ All documentation finalized
- ✅ Demo runbook verified
- ✅ Troubleshooting guide complete

---

## Deliverable Hygiene

- **No long code snippets** in planning docs
- **File trees + minimal stubs** only
- **Generate code** only where ambiguity would block next agent
- **DONE.md per agent** (only when approved by user)
- **Assumptions documented** in DONE.md
- **Next handoff steps** clearly stated

---

**Ready to execute agents in phase-aligned order: DXS → C&C Part 1 → A&D → ETA → C&C Part 2 → D&D**

