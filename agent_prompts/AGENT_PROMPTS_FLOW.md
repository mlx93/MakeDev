# Agent Prompts Flow & Execution Order
## Zero-to-Running Developer Environment

**Version:** 1.0  
**Last Updated:** November 10, 2025  
**Purpose**: Visual flow and overview of all agent prompts

---

## Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    MASTER AGENT                                  │
│              (Orchestrator)                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Spawns & Coordinates
                         │
         ┌────────────────┴────────────────┐
         │                                 │
         ▼                                 ▼
┌─────────────────┐              ┌─────────────────┐
│   DXS Agent     │              │   (Future)      │
│  (Planning)    │              │   Other Agents  │
│                 │              │                 │
│ ✅ COMPLETE     │              │                 │
└────────┬────────┘              └─────────────────┘
         │
         │ Handoff: File trees, Makefile stubs,
         │          config.yaml schema, ports,
         │          health checks, scaffolding design
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              C&C PART 1 AGENT                                    │
│         (Local Dev Infrastructure)                               │
│                                                                   │
│  Focus: Docker Compose, Dockerfiles, make dev working           │
│                                                                   │
│  Files Created:                                                  │
│  • docker/docker-compose.yml                                     │
│  • docker/Dockerfile.frontend                                   │
│  • docker/Dockerfile.backend                                    │
│  • scripts/check-prerequisites.sh                               │
│  • scripts/health-check.sh                                       │
│  • scripts/setup-local.sh                                       │
│  • Updated Makefile (dev target)                                 │
│                                                                   │
│  ✅ COMPLETE                                                     │
└────────┬──────────────────────────────────────────────────────────┘
         │
         │ Handoff: Working local dev environment,
         │          hot reload, health checks, scaffolding
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              A&D AGENT                                           │
│         (App & Data)                                             │
│                                                                   │
│  Focus: Tool infrastructure (seed generator, enhanced health)    │
│                                                                   │
│  Files Created:                                                  │
│  • scripts/seed-database.ts (schema-agnostic)                   │
│  • Enhanced health endpoints (database/Redis checks)             │
│  • Updated Makefile (seed target)                                 │
│  • Updated backend package.json (dependencies)                  │
│                                                                   │
│  ✅ COMPLETE                                                     │
└────────┬──────────────────────────────────────────────────────────┘
         │
         │ Handoff: Seed generator working,
         │          enhanced health checks,
         │          make seed command ready
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              ETA AGENT                                           │
│         (Example Task App)                                      │
│                                                                   │
│  Focus: Separate example-task-app repository                     │
│                                                                   │
│  Files Created:                                                  │
│  • example-task-app/ (complete repo)                             │
│  • Backend API (JWT auth + task CRUD)                            │
│  • Frontend app (React + Tailwind task management UI)            │
│  • Prisma schema (User + Task models)                            │
│  • Docker Compose configuration                                  │
│                                                                   │
│  ✅ COMPLETE                                                     │
└────────┬──────────────────────────────────────────────────────────┘
         │
         │ Handoff: Complete example app repo,
         │          works with make dev,
         │          ready for deployment testing
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              C&C PART 2 AGENT                                    │
│         (GKE Deployment Infrastructure)                          │
│                                                                   │
│  Focus: Terraform, K8s manifests, make deploy working         │
│                                                                   │
│  Files Created:                                                  │
│  • terraform/ (GKE cluster provisioning)                         │
│  • k8s/ (all Kubernetes manifests)                              │
│  • scripts/deploy-gke.sh                                        │
│  • scripts/env-to-k8s-secrets.sh                                │
│  • scripts/cleanup.sh                                           │
│  • Updated Makefile (deploy, destroy targets)                   │
└────────┬──────────────────────────────────────────────────────────┘
         │
         │ Handoff: Working GKE deployment,
         │          make deploy, make destroy
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              D&D AGENT                                           │
│         (Docs & Demo)                                           │
│                                                                   │
│  Focus: Documentation, troubleshooting, demo runbook           │
│                                                                   │
│  Files Created:                                                  │
│  • Updated READMEs                                               │
│  • DEMO_RUNBOOK.md                                              │
│  • TROUBLESHOOTING.md                                            │
│  • Golden outputs documented                                    │
└────────┬──────────────────────────────────────────────────────────┘
         │
         │ Handoff: Complete documentation,
         │          verified demo script
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PROJECT COMPLETE                              │
│                                                                   │
│  ✅ All phases complete                                          │
│  ✅ All quality gates passed                                     │
│  ✅ Ready for production use                                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent Summary Table

| Agent | Order | Phase | Focus | Key Deliverables | Status |
|-------|-------|-------|-------|------------------|--------|
| **DXS** | 1 | Planning | Structure & Design | File trees, Makefile stubs, config.yaml, scaffolding design | ✅ Complete |
| **C&C Part 1** | 2 | Phase 1 | Local Dev | Docker Compose, Dockerfiles, `make dev` working | ✅ Complete |
| **A&D** | 3 | Phase 3 | Tool Infrastructure | Seed generator, enhanced health endpoints | ✅ Complete |
| **ETA** | 4 | Phase 3 | Example App | example-task-app repository (full task CRUD app) | ✅ Complete |
| **C&C Part 2** | 5 | Phase 2 | GKE Deployment | Terraform, K8s manifests, `make deploy` working, GitHub automation | 📋 Prompt Ready |
| **D&D** | 6 | Phase 4 | Documentation | READMEs, troubleshooting, demo runbook | 📋 Pending |

---

## Phase Alignment

| Phase | Agents | Focus | Deliverables |
|-------|--------|-------|--------------|
| **Phase 1: Core Local Dev** | DXS + C&C Part 1 | Get `make dev` working | File trees, Docker Compose, `make dev` functional |
| **Phase 2: GKE Deployment** | C&C Part 2 | Get `make deploy` working | Terraform, K8s manifests, `make deploy` functional |
| **Phase 3: Advanced Features** | A&D + ETA | Build tool app + example app | Tool's backend/frontend, example-task-app repo |
| **Phase 4: Polish & Docs** | D&D | Documentation | READMEs, troubleshooting, demo runbook |

---

## Agent Prompt Files

| Agent | Prompt File | Location |
|-------|-------------|----------|
| DXS | `DXS_AGENT_PROMPT.md` | `agent_prompts/DXS_AGENT_PROMPT.md` |
| C&C Part 1 | `CC_PART1_AGENT_PROMPT.md` | `agent_prompts/CC_PART1_AGENT_PROMPT.md` |
| A&D | `A&D_AGENT_PROMPT.md` | `agent_prompts/A&D_AGENT_PROMPT.md` |
| ETA | `ETA_AGENT_PROMPT.md` | `agent_prompts/ETA_AGENT_PROMPT.md` |
| C&C Part 2 | `CC_PART2_AGENT_PROMPT.md` | `agent_prompts/CC_PART2_AGENT_PROMPT.md` |
| D&D | `D&D_AGENT_PROMPT.md` | `agent_prompts/D&D_AGENT_PROMPT.md` (to be created) |

---

## Quality Gates

Each agent must pass quality gates before proceeding:

### Gate 1: DXS Complete ✅
- File trees approved
- Makefile structure approved
- config.yaml schema approved
- Health check contracts defined
- Scaffolding system designed

### Gate 2: C&C Part 1 Complete ✅
- Docker Compose working
- `make dev` works end-to-end
- All services healthy locally
- Hot reload working
- Health checks pass locally
- Project scaffolding working
- Subdirectory support implemented

### Gate 3: A&D Complete ✅
- Seed generator working (schema-agnostic, reads Prisma dynamically)
- Enhanced health endpoints (database/Redis connectivity checks)
- `make seed` command working end-to-end
- All dependencies added to backend template

### Gate 4: ETA Complete ✅
- Example-task-app repo complete
- Works with `make dev` locally
- Full task CRUD functional (auth + backend + frontend)
- Demo user credentials available
- English seed data generation working

### Gate 5: C&C Part 2 Complete 📋
- `make deploy` works end-to-end
- `make destroy` works end-to-end
- All services healthy in GKE

### Gate 6: D&D Complete 📋
- All documentation finalized
- Demo runbook verified
- Troubleshooting guide complete

---

## Key Handoff Points

### DXS → C&C Part 1
- File trees defined
- Ports fixed (3000, 8080, 5432, 6379)
- Health check contracts (`{status: "ok"}`)
- config.yaml schema documented
- Makefile structure approved

### C&C Part 1 → A&D
- `make dev` works end-to-end
- Hot reload configured
- Health checks pass locally
- Docker Compose working

### A&D → ETA
- Seed generator working (ready for User/Task schema)
- Enhanced health endpoints implemented
- `make seed` command available
- Tool infrastructure complete (ETA builds example-task-app)

### ETA → C&C Part 2
- Example app complete and tested
- Works with `make dev` locally
- Full authentication and CRUD functional
- Ready for GKE deployment testing

### C&C Part 2 → D&D
- `make deploy` works end-to-end
- `make destroy` works end-to-end
- All services healthy in local and GKE

---

## Common Patterns Across Agents

1. **Single DONE.md File**: All planning artifacts go into ONE DONE.md file (no separate MD files)
2. **PRD References**: Always reference PRD_1 and PRD_2 as source of truth
3. **Quality Gates**: Must pass quality gates before handoff
4. **Idempotency**: All operations safe to run multiple times
5. **Simple Error Messages**: Clear, actionable, not verbose
6. **Health Checks**: `{status: "ok"}` format for all services

---

## Execution Timeline

**Estimated Duration**: 6-8 weeks total

- **Week 1**: DXS (Planning) ✅ Complete
- **Week 1-2**: C&C Part 1 (Local Dev) ✅ Complete
- **Week 2-3**: A&D (Tool Infrastructure) ✅ Complete
- **Week 3-4**: ETA (Example App) ✅ Complete
- **Week 4-5**: C&C Part 2 (GKE Deployment) 📋 Ready to Start
- **Week 5-6**: D&D (Documentation) 📋 Pending

---

**This flow ensures local dev works before building app, and app works before deployment.**

