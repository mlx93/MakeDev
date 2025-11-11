# Project Brief: Zero-to-Running Developer Environment

**Version:** 1.0  
**Last Updated:** November 10, 2025  
**Status:** In Progress - Phase 1 Complete

---

## Vision

A universal bootstrapping tool that enables developers to go from zero to a fully running multi-service environment (React + Node.js + PostgreSQL + Redis) with a single command (`make dev`). Supports local development via Docker Compose and production deployment to Google Kubernetes Engine (GKE).

---

## Core Requirements

### Primary Goals
- **Single command setup**: `make dev` starts all services in < 10 minutes
- **Zero manual configuration**: Convention over configuration, minimal config.yaml
- **Production-ready**: `make deploy` provisions GKE and deploys application
- **Smart scaffolding**: Empty repo → "hello world" React + Node.js app (with pre-commit hooks + GitHub Actions)
- **Database seeding**: Realistic fake data generation from Prisma schema

### Technology Stack (Pinned Versions)
- **Frontend**: React 18.2 + Vite 5.0 + TypeScript 5.3 + Tailwind CSS 3.4
- **Backend**: Node.js 20 LTS + Express 4.18 + TypeScript 5.3 + Prisma 5.7
- **Database**: PostgreSQL 16
- **Cache**: Redis 7.2 (optional for users, but tool must support it)
- **Local**: Docker Compose
- **Production**: GKE + Kubernetes + Terraform

### Platform Constraints
- **macOS only** (primary platform)
- **Docker Desktop** required (not Docker Engine)
- **GCP project must exist** (user provides project_id)
- **Artifact Registry** (not legacy GCR)
- **Terraform state in GitHub** (version controlled)

---

## Key Design Decisions

1. **Express backend** (not Dora framework)
2. **Backend internal only** (ClusterIP service, not LoadBalancer)
3. **Cluster reuse automatic** (detect existing, reuse if found)
4. **.env.production preferred** for GKE (fallback to .env)
5. **Pin dependency versions** (exact versions, no ranges)
6. **Redis support built-in** (tool supports it, user can disable in their project)
7. **Fixed ports** (3000, 8080, 5432, 6379) - not configurable
8. **Health check format**: `{status: "ok"}` - simple JSON
9. **Migrations auto-run** on `make dev` startup (no separate command)
10. **Subdirectory support** - `make dev SUBDIR=name` for isolated projects

---

## Current Status

### Completed Phases

**Phase 1: Core Local Dev** ✅
- DXS Agent: Planning & structure complete
- C&C Part 1 Agent: Local dev infrastructure complete
  - Docker Compose working
  - Dockerfiles created (dev stage)
  - `make dev` works end-to-end
  - Hot reload working (Vite HMR + tsx watch)
  - Health checks pass locally
  - Project scaffolding system implemented
  - Subdirectory support (`make dev SUBDIR=name`)

### In Progress

**Phase 3: Advanced Features** 🔄
- A&D Agent: Ready to start (prompt generated)
  - Will implement tool's backend/frontend
  - Will implement seed generator
  - Will enhance health endpoints

### Pending Phases

- **Phase 3**: ETA Agent (Example Task App)
- **Phase 2**: C&C Part 2 Agent (GKE Deployment)
- **Phase 4**: D&D Agent (Documentation)

---

## Success Criteria

- [x] `make dev` works end-to-end locally
- [ ] `make seed` generates realistic fake data
- [ ] `make deploy` deploys to GKE successfully
- [ ] `make destroy` cleanly removes all resources
- [ ] All health checks pass in local and GKE
- [ ] Documentation complete and verified

---

## Key Documents

- **PRD_1_Product_v2.md** - Product requirements (source of truth)
- **PRD_2_Tech_Spec_v2.md** - Technical specifications (source of truth)
- **IMPLEMENTATION_GUIDE.md** - Implementation structure
- **DONE.md** (from DXS) - Planning artifacts
- **agent_reports/cc_part1_agent_done_report.md** - C&C Part 1 completion report

---

**Project is on track. Phase 1 complete, ready for Phase 3 (A&D agent).**

