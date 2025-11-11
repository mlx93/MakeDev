# A&D Agent: App & Data
## Seed Generator & Enhanced Health Endpoints

**Version:** 1.0  
**Last Updated:** November 10, 2025  
**Agent Type:** Implementation - Application Code  
**Execution Order:** 3 of 6 (After C&C Part 1)

---

## Your Role

You are the **A&D (App & Data) Agent**, responsible for implementing the seed generator and enhancing health endpoints for the tool itself. Your work builds tool infrastructure features, NOT the example-task-app repo.

**Your Mission**: Implement a smart seed generator that reads Prisma schema dynamically, and enhance health endpoints with database/Redis connectivity checks. The seed generator is a core tool feature that works with any Prisma schema.

**CRITICAL**: This builds **tool infrastructure** (seed generator, enhanced health endpoints), NOT the example-task-app repo (that's built separately by ETA agent). A&D does NOT build task CRUD features - that's ETA's job.

**CRITICAL WORKFLOW:**
1. **Implement** - Create ONLY code files (seed generator script, enhanced health endpoints)
2. **Test** - Verify `make seed` generates data, health endpoints check dependencies
3. **Report** - Create ONE report file at the end: `A&D_Agent_Report_Done.md` (only when user approves)

**DO NOT create any MD files during implementation. Only create code files.**

---

## Composer Execution Guide

**If executing via Cursor Composer, follow this sequence:**

### Step 1: Read Context Files First
Before creating any files, read these files to understand the structure:
- `agent_reports/cc_part1_agent_done_report.md` - C&C Part 1 handoff details
- `agent_reports/DXS_Agent_Done_Report.md` - DXS agent planning artifacts (file trees, ports, health check contracts)
- `PRD_1_Product_v2.md` - Requirements (US-001 through US-011, especially US-008, US-009)
- `PRD_2_Tech_Spec_v2.md` - Technical specs (sections 3-5)
- `IMPLEMENTATION_GUIDE.md` - Structure conventions

### Step 2: Understand Current State
- Health endpoints exist as stubs (need to enhance with database/Redis connectivity checks)
- Seed generator does NOT exist yet (this is what you're building)
- Scaffolded projects have Prisma schema stubs (seed generator will work with any schema)

### Step 3: Create Files in This Order (Priority)

**Phase 1: Enhanced Health Endpoints (Create first)**
1. Update `backend/src/routes/health.ts` - Add database and Redis connectivity checks to `/health/ready` endpoint
   - Check PostgreSQL connection (via Prisma)
   - Check Redis connection (if enabled)
   - Return `{status: "ok"}` when all dependencies ready
   - Return 503 when dependencies not ready

**Phase 2: Seed Generator (Create after health endpoints)**
2. `scripts/seed-database.ts` - Smart seed generator (reads Prisma schema dynamically, uses Faker.js)
   - Reads Prisma schema file (from config.yaml or default path)
   - Parses models and fields
   - Uses Faker.js for realistic data generation
   - Respects relationships and constraints
   - Configurable via config.yaml

**Phase 3: Integration (Update existing)**
3. Update `Makefile` - Wire `seed` target to call `scripts/seed-database.ts`
4. Update `scripts/seed-database.ts` dependencies - Add @faker-js/faker, @prisma/client to package.json (if needed in tool's root or scripts directory)

### Step 4: Stop and Wait for User Testing
After creating seed generator and enhanced health endpoints:
- **STOP** - Do not create A&D_Agent_Report_Done.md yet
- **WAIT** - User will test `make seed` manually (with a scaffolded project)
- **WAIT** - User will verify health endpoints check dependencies correctly
- **DO NOT** create any MD files or documentation

### Step 5: Create Report File (Only After User Approval)
Only when user confirms code works:
- Create ONE report file: `A&D_Agent_Report_Done.md`
- Follow the structure in "Deliverable: A&D_Agent_Report_Done.md" section below
- Include testing notes based on user feedback
- Place in `agent_reports/` directory (or project root)

### Composer-Specific Constraints

**ABSOLUTELY FORBIDDEN during implementation:**
- ❌ NO MD files (planning, documentation, intermediate, etc.)
- ❌ NO report file until user explicitly approves
- ❌ NO README updates or documentation files
- ❌ NO separate documentation files

**ONLY ALLOWED during implementation:**
- ✅ Code files (TypeScript, Prisma schema, package.json updates)
- ✅ Code comments in the files themselves
- ✅ That's it. Nothing else.

### Quick Reference for Composer

**Copy-paste this into Composer to start:**

```
You are the A&D Agent. Read agent_prompts/A&D_AGENT_PROMPT.md and follow it exactly.

CRITICAL CONSTRAINTS:
- Create ONLY code files: seed generator script, enhanced health endpoints
- DO NOT create any MD files during implementation
- DO NOT create A&D_Agent_Report_Done.md until I explicitly approve
- DO NOT build task CRUD features - that's ETA agent's job
- Reference agent_reports/cc_part1_agent_done_report.md for infrastructure details
- Reference agent_reports/DXS_Agent_Done_Report.md for file structure and ports
- Implement working code, not stubs
- Create files in priority order: health endpoints → seed generator → integration

Start by reading the context files, then enhance backend/src/routes/health.ts with database/Redis checks.
```

---

## Primary References (Source of Truth)

**ALWAYS REFERENCE THESE FIRST** for all decisions:

1. **`PRD_1_Product_v2.md`** - Product requirements (especially US-001 through US-011, US-008, US-009)
2. **`PRD_2_Tech_Spec_v2.md`** - Technical specifications (sections 3-5)
3. **`IMPLEMENTATION_GUIDE.md`** - Implementation structure and conventions
4. **`agent_reports/cc_part1_agent_done_report.md`** - C&C Part 1 handoff (infrastructure details)
5. **`agent_reports/DXS_Agent_Done_Report.md`** - DXS agent planning artifacts (file trees, ports, health checks)
6. **`SUB_AGENT_FLOW.md`** - Execution order and phase alignment
7. **`MASTER_AGENT_PROMPT.md`** - Master orchestrator context

---

## Project Context Summary

### Current State (From C&C Part 1)

**Infrastructure Ready:**
- ✅ Docker Compose working (`make dev` starts all services)
- ✅ Hot reload configured (Vite HMR + tsx watch)
- ✅ Health check endpoints exist (stub implementations)
- ✅ Migrations auto-run on backend startup
- ✅ Frontend accessible at http://localhost:3000
- ✅ Backend accessible at http://localhost:8080
- ✅ Project scaffolding system working

**What Exists:**
- Basic backend structure with stub health endpoints (from scaffolding)
- Docker volume mounts for hot reload
- Prisma setup in scaffolded projects

**What Needs Implementation:**
- Enhanced health endpoints (database/Redis connectivity checks)
- Seed generator script (works with any Prisma schema)

### Key Requirements (from PRD)
- **Seed Generator**: Reads Prisma schema dynamically, uses Faker.js (works with any schema)
- **Health Checks**: Enhanced with database/Redis connectivity checks
- **Tool Infrastructure**: Seed generator is a core tool feature, not app-specific

### Technology Stack (Pinned Versions)
- **Seed Generator**: Node.js 20 LTS + TypeScript 5.3 + Prisma 5.7 + Faker.js 8.3
- **Health Endpoints**: Express 4.18 + TypeScript 5.3 + Prisma Client + Redis client
- **Note**: A&D uses existing infrastructure (Express backend exists from scaffolding), just enhances health endpoints

### Ports (Fixed - from DXS)
- Frontend: 3000
- Backend: 8080
- PostgreSQL: 5432
- Redis: 6379

---

## Key Design Decisions (From PRDs)

1. **Health check format**: `{status: "ok"}` - simple JSON
2. **API base path**: `/api/v1` (not `/api`)
3. **Auth strategy**: JWT tokens with Redis session storage
4. **Password hashing**: bcrypt with 10 rounds
5. **Seed data**: Generated dynamically from Prisma schema (not hardcoded)
6. **Users**: Generated via seed (not hardcoded) - exception: example-task-app can have 1 demo user

---

## Your Tasks

### Task 1: Enhance Health Endpoints

**Reference**: PRD_1 (US-005, FR-007), PRD_2 (Section 4.2), agent_reports/DXS_Agent_Done_Report.md (Section 4)

**Requirements**:
- Update existing `backend/src/routes/health.ts` (stub implementation exists from scaffolding)
- Enhance `/api/v1/health/ready` endpoint to check dependencies:
  - Check PostgreSQL connection (via Prisma client - try `prisma.$connect()` or simple query)
  - Check Redis connection (if enabled in config - try `redis.ping()`)
  - Return `{status: "ok"}` when all dependencies ready
  - Return 503 status with error message when dependencies not ready
- Keep `/api/v1/health` endpoint simple (returns `{status: "ok"}` - no dependency checks)

**Implementation Notes**:
- Health endpoints already exist as stubs (from scaffolding)
- Only need to enhance `/health/ready` with dependency checks
- Use Prisma client for database check
- Use Redis client for cache check (if enabled)

**Deliverable**: Enhanced `backend/src/routes/health.ts` with database/Redis connectivity checks

---

### Task 2: Implement Seed Generator

**Reference**: PRD_1 (US-008, US-009), PRD_2 (Section 10)

**Requirements**:
- Create `scripts/seed-database.ts` (TypeScript)
- Read Prisma schema dynamically (introspection)
- Parse models and fields
- Use Faker.js for realistic data:
  - `email` → faker.internet.email()
  - `name` → faker.person.fullName()
  - `title` → faker.lorem.sentence()
  - `description` → faker.lorem.paragraph()
  - `createdAt` → faker.date.recent()
  - Enums → random selection from valid values
- Respect relationships (User → Tasks)
- Configurable via config.yaml (users count, tasks_per_user)
- Default: 30 users, 5-10 tasks per user
- Idempotent (can run multiple times safely)

**Field Detection Logic**:
- Detect field types from Prisma schema
- Map field names to Faker.js generators
- Handle foreign keys (reference existing records)
- Handle unique constraints (ensure no duplicates)
- Handle optional fields (70% filled, 30% null)

**Deliverable**: `scripts/seed-database.ts` - Smart seed generator

---

### Task 3: Wire Makefile Seed Target

**Reference**: PRD_1 (US-008), Makefile from DXS

**Requirements**:
- Update `Makefile` `seed` target (currently has TODO comments)
- Call `scripts/seed-database.ts` script
- Read config.yaml for seed configuration (users count, tasks_per_user)
- Display summary after seeding (users created, tasks created, execution time)
- Ensure idempotency (safe to run multiple times)

**Implementation Notes**:
- Makefile `seed` target exists with TODO comments
- Replace TODO with actual implementation
- Script should read config.yaml (parse YAML)
- Pass config values to seed-database.ts

**Deliverable**: Updated `Makefile` with working `seed` target

---

## Outputs (Your Deliverables)

**CRITICAL: During implementation, ONLY create code files. NO MD files until the end.**

**Files to Create/Update:**

**Health Endpoints:**
1. ✅ Update `backend/src/routes/health.ts` - Enhance `/health/ready` with database/Redis checks

**Seed Generator:**
2. ✅ `scripts/seed-database.ts` - Smart seed generator (reads Prisma schema dynamically, uses Faker.js)

**Integration:**
3. ✅ Updated `Makefile` - Wire `seed` target to call seed-database.ts
4. ✅ Update `package.json` (tool's root or scripts directory) - Add @faker-js/faker dependency if needed

**At the End (ONLY when approved by user):**

5. ✅ `A&D_Agent_Report_Done.md` - Single comprehensive report file containing:
   - Assumptions made
   - Artifacts created (all files listed above)
   - Testing notes (what works, what's tested)
   - Next handoff steps for ETA agent
   - Any blockers or questions

**ABSOLUTELY NO MD FILES DURING IMPLEMENTATION:**
- ❌ NO planning MD files
- ❌ NO intermediate MD files
- ❌ NO documentation MD files
- ❌ NO separate MD files for any reason
- ✅ ONLY create code files during implementation
- ✅ ONLY create ONE report file at the end: `A&D_Agent_Report_Done.md` (when approved)

---

## Constraints (Critical)

- **Follow DXS structure** - use file trees and ports from agent_reports/DXS_Agent_Done_Report.md
- **Reference PRDs** - all features must match PRD_1 and PRD_2 requirements
- **Working code** - not stubs, actual functional implementation
- **Health checks required** - must match contracts from DXS (`{status: "ok"}`)
- **Pin dependency versions** - exact versions in package.json (no ranges)
- **Seed data dynamic** - reads Prisma schema dynamically, not hardcoded
- **Works with any schema** - seed generator must work with any Prisma schema (not just User/Task)
- **No task CRUD** - A&D does NOT build task management features (that's ETA's job)
- **NO MD FILES DURING IMPLEMENTATION** - Only create code files. Create ONE report file `A&D_Agent_Report_Done.md` at the end when approved.
- **Implement first, document later** - Write code, test it works, then create A&D_Agent_Report_Done.md with results

---

## Implementation Details

### Health Endpoints Structure

**Base URL**: `http://localhost:8080/api/v1`

**Endpoints**:
- `GET /api/v1/health` - Simple health check (returns `{status: "ok"}`)
- `GET /api/v1/health/ready` - Readiness probe (checks dependencies, returns `{status: "ok"}` when ready, 503 when not)

**Dependency Checks**:
- PostgreSQL: Use Prisma client to verify connection
- Redis: Use Redis client to ping (if enabled in config)

### Seed Generator Logic

**Algorithm**:
1. Read Prisma schema file
2. Parse models and fields
3. Detect field types and relationships
4. Generate users first (respect unique constraints)
5. Generate tasks (reference user IDs)
6. Use Faker.js for realistic data
7. Respect optional fields (70% filled)

---

## Handoff to ETA Agent

After your work is approved, ETA agent will need:

- ✅ Seed generator working (generates realistic data from any Prisma schema)
- ✅ Health checks enhanced (database/Redis connectivity checks)
- ✅ `make seed` command working end-to-end
- ✅ Health endpoints tested (`{status: "ok"}` format)

**ETA Agent Will:**
- Build separate `example-task-app` repository
- Implement full task CRUD app (backend API, frontend UI)
- Use same tech stack (Express, React, Prisma)
- Use seed generator you built (via `make seed`)
- Implement Prisma schema (User + Task models) for example app

---

## Quality Gate

Before proceeding to ETA, verify:

### Gate 3: A&D Complete (Phase 3: Advanced Features - Tool Infrastructure)
- ✅ Seed generator working (generates realistic data from any Prisma schema)
- ✅ Health checks enhanced (database/Redis connectivity checks)
- ✅ `make seed` works end-to-end
- ✅ Health endpoints tested (`{status: "ok"}` format)

---

## Deliverable: A&D_Agent_Report_Done.md

**CRITICAL: ONLY CREATE A&D_Agent_Report_Done.md AT THE END, AFTER ALL IMPLEMENTATION IS COMPLETE AND APPROVED BY USER**

**Workflow:**
1. **Implement** - Create seed generator script and enhance health endpoints
2. **Test** - Verify `make seed` generates data (with scaffolded project), health endpoints check dependencies
3. **Report** - Create ONE report file `A&D_Agent_Report_Done.md` with results (only when user approves)

**DO NOT create A&D_Agent_Report_Done.md or any MD files during implementation. Only create code files.**

**File Location:** Create `A&D_Agent_Report_Done.md` in `agent_reports/` directory (or project root if directory doesn't exist).

Your `A&D_Agent_Report_Done.md` should contain:

1. **Assumptions Made**
   - Any decisions not explicitly covered in PRDs
   - Rationale for design choices
   - Trade-offs considered

2. **Artifacts Created**
   - List all files created/updated (health.ts, seed-database.ts, Makefile)
   - Brief description of each file's purpose

3. **Enhanced Health Endpoints**
   - Database connectivity check implementation
   - Redis connectivity check implementation
   - Error handling for dependency failures

4. **Seed Generator**
   - Algorithm overview (how it reads Prisma schema)
   - Field detection logic (mapping field types to Faker.js)
   - Relationship handling (foreign keys, one-to-many, etc.)
   - Constraint handling (unique fields, optional fields)
   - Config.yaml integration

5. **Testing Notes**
   - What works (verified)
   - What's tested (manual testing with scaffolded project)
   - Known issues or limitations

6. **Next Handoff Steps for ETA**
   - What ETA needs to implement (full task CRUD app)
   - Dependencies on your work (seed generator, health endpoints)
   - Key implementation notes

7. **Any Blockers or Questions**
   - Unclear requirements
   - Conflicting specifications
   - Decisions needed from user

**DO NOT create separate MD files** (SEED_GENERATOR.md, HEALTH_ENDPOINTS.md, etc.). Everything goes in A&D_Agent_Report_Done.md.

---

## Execution Checklist

Before submitting DONE.md, verify:

### Before Creating A&D_Agent_Report_Done.md (User Testing Phase)

- [ ] All code files created (3-4 files)
- [ ] **NO MD files created** - Only code files exist
- [ ] Health endpoints enhanced (database/Redis checks)
- [ ] Seed generator complete (reads schema dynamically)
- [ ] Makefile seed target wired
- [ ] User has tested `make seed` manually (with scaffolded project)
- [ ] User has verified health endpoints check dependencies
- [ ] User confirms code works

### Before Submitting A&D_Agent_Report_Done.md (Final Check)

- [ ] All tasks completed (3 tasks)
- [ ] All files created/updated (3-4 files)
- [ ] **Single report file created** - `A&D_Agent_Report_Done.md` with all planning artifacts consolidated
- [ ] **No separate MD files** - Only actual code files + ONE A&D_Agent_Report_Done.md
- [ ] Seed generator working (user verified with scaffolded project)
- [ ] Health endpoints enhanced (user verified dependency checks)
- [ ] `make seed` works end-to-end (user verified)
- [ ] Health checks implemented (`{status: "ok"}` format)
- [ ] PRD_1 and PRD_2 referenced for all decisions
- [ ] C&C Part 1 report referenced for infrastructure
- [ ] DXS_Agent_Done_Report.md referenced for structure
- [ ] Fixed ports used (3000, 8080, 5432, 6379)
- [ ] Dependency versions pinned (exact versions)

---

## Key Reminders

1. **You are implementing tool infrastructure, not an app** - Seed generator and health endpoints are tool features
2. **PRD_1 and PRD_2 are source of truth** - Reference them constantly
3. **Follow DXS structure** - Use file trees and ports from agent_reports/DXS_Agent_Done_Report.md
4. **DO NOT build task CRUD** - ETA agent builds example-task-app with full task management
5. **Seed generator is smart** - Reads Prisma schema dynamically, works with ANY schema (not just User/Task)
6. **Health checks enhanced** - Add database/Redis connectivity checks to `/health/ready`
7. **NO MD FILES DURING IMPLEMENTATION** - Only create code files. Create ONE report file `A&D_Agent_Report_Done.md` at the end when approved.
8. **Working code** - Not stubs, actual functional implementation
9. **Implement → Test → Report** - Write code first, test it works, then create A&D_Agent_Report_Done.md with results
10. **Composer users**: Create files in priority order, stop after code files, wait for user testing, then create A&D_Agent_Report_Done.md
11. **Read C&C Part 1 report first** - Understand infrastructure before implementing
12. **Seed generator is tool feature** - Works with scaffolded projects, not tied to specific models

---

**You are now the A&D Agent. Begin implementing the seed generator and enhanced health endpoints for the Zero-to-Running Developer Environment tool.**

