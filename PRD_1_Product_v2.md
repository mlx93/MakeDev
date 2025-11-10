# Zero-to-Running Developer Environment
## Product Requirements Document (PRD)

**Version:** 1.0  
**Last Updated:** November 10, 2025  
**Document Type:** Product Requirements  
**Status:** Draft for Review

---

## 1. Executive Summary

### 1.1 Product Vision

The Zero-to-Running Developer Environment is a universal bootstrapping tool that eliminates the complexity of local development setup for modern web applications. By executing a single command (`make dev`), developers can instantly provision a fully functional multi-service environment with React frontend, Node.js backend, PostgreSQL database, and optional Redis cache—all containerized, orchestrated, and ready for production deployment.

This tool addresses the critical pain point of developer onboarding and environment inconsistency by providing:
- **Instant Setup**: Clone → Configure → Run (under 10 minutes)
- **Environment Parity**: Identical local and production infrastructure
- **Smart Scaffolding**: Auto-generates project structure for new applications
- **Production-Ready**: One-command deployment to Google Kubernetes Engine (GKE)

### 1.2 Problem Statement

Modern web development requires orchestrating multiple interconnected services—frontend frameworks, backend APIs, databases, caches, and authentication layers. Setting up these environments manually leads to:

1. **Onboarding Friction**: New developers spend 2-8 hours configuring environments before writing code
2. **"Works on My Machine" Syndrome**: Environment inconsistencies cause deployment failures
3. **Configuration Drift**: Local and production environments diverge over time
4. **Knowledge Silos**: Environment setup requires DevOps expertise most developers lack
5. **Cognitive Overhead**: Developers waste mental energy on infrastructure instead of features

**Target Impact**: Enable developers to go from repository clone to running application in under 10 minutes, reducing onboarding time by 90% and environment-related issues by 95%.

### 1.3 Product Scope

**In Scope:**
- Local development environment via Docker Compose
- Production deployment to GKE via Kubernetes
- Support for React/Tailwind + Node.js/TypeScript + PostgreSQL + Redis stack
- Automatic project scaffolding for empty repositories
- Smart database seeding with realistic fake data
- Secret management (local mock secrets, production K8s secrets)
- Health checks and service dependency management
- Hot reload for frontend and backend
- Database migrations via Prisma
- Infrastructure as Code (Terraform for GKE provisioning)

**Out of Scope:**
- Support for other tech stacks (Python/Django, Ruby/Rails, etc.)
- Advanced CI/CD pipeline integration
- Production-grade monitoring/alerting setup
- Multi-region deployment
- Auto-scaling configuration
- SSL/HTTPS certificate management

### 1.4 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to Running Environment | < 10 minutes | Time from `git clone` to all services healthy |
| Developer Onboarding Time | < 1 hour | Time for new developer to make first code commit |
| Environment-Related Support Tickets | 90% reduction | Tickets tagged with "environment", "setup", "docker" |
| Local/Production Parity | 100% | Configuration differences between environments |
| First-Time Setup Success Rate | > 95% | Percentage of successful `make dev` executions |
| GKE Deployment Success Rate | > 90% | Percentage of successful `make deploy` executions |

---

## 2. Target Users & Personas

### 2.1 Primary Personas

#### Persona 1: "Alex" - The New Developer
- **Background**: Junior to mid-level engineer, recently joined a team
- **Experience**: Familiar with React and Node.js, limited DevOps knowledge
- **Pain Points**: 
  - Overwhelmed by complex setup instructions
  - Struggles with Docker and Kubernetes concepts
  - Wants to contribute code on day one
- **Goals**:
  - Get environment running without asking for help
  - Understand basic service architecture
  - Focus on learning the codebase, not infrastructure
- **Success Scenario**: Runs `make dev`, sees services start, reads code, makes first PR within 4 hours

#### Persona 2: "Jordan" - The Full-Stack Developer
- **Background**: Experienced engineer working across multiple projects
- **Experience**: Strong development skills, basic ops knowledge
- **Pain Points**:
  - Wastes time context-switching between project environments
  - Different projects have different setup procedures
  - Wants to prototype new ideas quickly
- **Goals**:
  - Spin up environments in minutes, not hours
  - Test changes locally before pushing
  - Deploy to staging/production with confidence
- **Success Scenario**: Clones tool, points to new project, runs `make dev`, builds feature, runs `make deploy`

#### Persona 3: "Sam" - The DevOps Engineer
- **Background**: Platform/infrastructure engineer supporting development teams
- **Experience**: Expert in Docker, Kubernetes, cloud infrastructure
- **Pain Points**:
  - Spends too much time supporting individual developer environments
  - Difficult to standardize across teams
  - Manual processes don't scale
- **Goals**:
  - Provide self-service developer tools
  - Ensure local/production parity
  - Reduce environment-related support burden
- **Success Scenario**: Deploys tool to organization, onboards teams with documentation, support tickets drop 90%

### 2.2 Secondary Personas

#### Persona 4: "Taylor" - The Startup Founder/Tech Lead
- **Goals**: Rapid prototyping, quick MVP deployment, minimal infrastructure management
- **Success Scenario**: Uses empty-repo scaffolding to generate new project, deploys to GKE in 1 day

#### Persona 5: "Casey" - The Open Source Contributor
- **Goals**: Contribute to projects without environment setup friction
- **Success Scenario**: Finds project using this tool, runs `make dev`, submits PR same day

---

## 3. User Stories

### 3.1 Core User Stories (P0 - Must Have)

#### Epic 1: Local Environment Setup

**US-001**: As a **new developer**, I want to clone a repository and run a single command to set up my local environment, so that I can start coding immediately without manual configuration.
- **Acceptance Criteria**:
  - Single command (`make dev`) starts all services
  - Frontend accessible at http://localhost:3000
  - Backend API accessible at http://localhost:8080
  - Database initialized with schema
  - Redis cache running (if configured)
  - All health checks pass
  - Setup completes in < 10 minutes

**US-002**: As a **developer**, I want the tool to automatically detect my project structure and technology requirements, so that I don't need to write complex configuration files.
- **Acceptance Criteria**:
  - Reads `package.json` to identify React and Node.js
  - Detects conventional folder structure (`/frontend`, `/backend`)
  - Discovers `schema.prisma` location automatically
  - Uses sensible defaults for all configurations
  - Allows optional overrides via `config.yaml`

**US-003**: As a **developer**, I want database migrations to run automatically during environment setup, so that my database schema is always up-to-date.
- **Acceptance Criteria**:
  - Prisma migrations run automatically on `make dev` startup
  - Migration status visible in logs
  - Migration failures stop environment startup with clear error
  - No separate migration command needed (auto-run is sufficient)

**US-004**: As a **developer**, I want hot reload for both frontend and backend code, so that I can see changes immediately without restarting services.
- **Acceptance Criteria**:
  - Frontend (Vite) hot module replacement works
  - Backend (tsx watch) restarts on file changes
  - Changes reflected in < 2 seconds
  - Hot reload preserves application state where possible

**US-005**: As a **developer**, I want clear health check indicators for all services, so that I know when the environment is ready.
- **Acceptance Criteria**:
  - Each service exposes `/health` endpoint
  - Startup script waits for all health checks before marking "ready"
  - Failed health checks display actionable error messages
  - Health status visible via `make status` command

#### Epic 2: Project Scaffolding

**US-006**: As a **developer starting a new project**, I want the tool to generate a basic project structure if my repository is empty, so that I can start with best practices out of the box.
- **Acceptance Criteria**:
  - Detects empty repository (no frontend/backend folders)
  - Generates "hello world" level React/Tailwind frontend with basic structure
  - Generates "hello world" level Node.js/TypeScript backend with basic API routes
  - Creates Prisma schema with User and Task models
  - Includes pre-commit hooks (Husky + lint-staged) for ESLint
  - Includes GitHub Actions workflow (`.github/workflows/lint.yml`) for linting
  - Generated code follows TypeScript best practices
  - **Note**: Full example task list application is provided separately as `example-task-app` repository (see US-007, US-008)

**US-007**: As a **developer**, I want the scaffolded project to include a working authentication pattern, so that I understand how to handle auth in my real application.
- **Acceptance Criteria**:
  - Mock authentication with hardcoded users
  - JWT token generation and validation
  - Password hashing with bcrypt
  - Session management via Redis
  - Login/logout endpoints functional
  - Frontend auth state management

#### Epic 3: Database Seeding

**US-008**: As a **developer**, I want to generate realistic fake data for my database with a single command, so that I can test my application with meaningful data.
- **Acceptance Criteria**:
  - `make seed` command generates fake data
  - Reads Prisma schema to understand model relationships
  - Uses Faker.js for realistic data (emails, names, dates, etc.)
  - Respects unique constraints and foreign keys
  - Configurable seed amounts in `config.yaml`
  - Default: 30 users with 5-10 tasks each
  - Idempotent (can run multiple times safely)

**US-009**: As a **developer**, I want the seed generator to intelligently map field types to realistic data, so that my test data looks production-like.
- **Acceptance Criteria**:
  - `email` fields → valid email addresses
  - `name` fields → realistic names
  - `createdAt` fields → recent timestamps
  - `status` enums → random valid values
  - Foreign keys → valid references to related records
  - Optional fields → 70% filled, 30% null

#### Epic 4: Configuration Management

**US-010**: As a **developer**, I want to configure my environment using a simple YAML file, so that I can customize settings without modifying infrastructure code.
- **Acceptance Criteria**:
  - `config.yaml` in tool repository
  - Documented configuration options with examples
  - Optional overrides for all defaults
  - Validates configuration on startup
  - Clear error messages for invalid config

**US-011**: As a **developer**, I want my environment variables and secrets to be handled securely, so that I don't accidentally commit sensitive data.
- **Acceptance Criteria**:
  - `.env.example` provided with placeholder values
  - `.env` in `.gitignore`
  - Local development uses mock secrets
  - Secrets injected into containers (not embedded in images)
  - JWT secrets, database passwords, API keys all handled
  - Documentation on secret rotation

#### Epic 5: GKE Deployment

**US-012**: As a **developer**, I want to deploy my application to Google Kubernetes Engine with a single command, so that I can test in a production-like environment.
- **Acceptance Criteria**:
  - `make deploy` deploys to GKE
  - Terraform provisions GKE cluster if needed
  - Detects existing cluster and reuses it
  - Configurable via `config.yaml` (project ID, region, cluster name)
  - All services deployed as K8s resources
  - LoadBalancer exposes frontend publicly
  - Deployment completes in < 15 minutes

**US-013**: As a **developer**, I want my local environment variables to be automatically converted to Kubernetes secrets, so that I don't need to manually configure production secrets.
- **Acceptance Criteria**:
  - `.env` values converted to K8s ConfigMaps (non-sensitive)
  - `.env` values converted to K8s Secrets (sensitive)
  - Automatic detection of sensitive keys (password, secret, key, token)
  - Option to prompt for production values during deployment
  - Deployed secrets never logged or displayed

**US-014**: As a **developer**, I want to tear down my GKE deployment to avoid unexpected costs, so that I can safely experiment without budget concerns.
- **Acceptance Criteria**:
  - `make destroy` command removes all GKE resources
  - Prompts for confirmation before destruction
  - Optionally preserves cluster, only removes application
  - Displays estimated cost savings
  - Terraform state properly cleaned up

### 3.2 Enhanced User Stories (P1 - Should Have)

**US-015**: As a **developer**, I want automatic service dependency ordering, so that services start in the correct sequence without failures.
- **Acceptance Criteria**:
  - Database starts before backend
  - Backend waits for database to be healthy
  - Frontend starts only after backend is ready
  - Dependency failures trigger graceful error messages

**US-016**: As a **developer**, I want meaningful logs during startup, so that I can understand what's happening and debug issues.
- **Acceptance Criteria**:
  - Clear, color-coded log output
  - Progress indicators for each step
  - Service-specific logs easily accessible
  - Log aggregation command (`make logs`)
  - Errors highlighted with troubleshooting hints

**US-017**: As a **developer**, I want graceful error handling for common setup issues, so that I don't get stuck on basic problems.
- **Acceptance Criteria**:
  - Port conflicts detected, alternatives suggested
  - Missing Docker installation detected with fix instructions
  - Network issues identified with troubleshooting steps
  - Invalid configuration caught with helpful error messages

### 3.3 Nice-to-Have User Stories (P2)

**US-018**: As a **developer**, I want a GitHub Actions workflow for linting, so that code quality is enforced automatically.
- **Acceptance Criteria**:
  - `.github/workflows/lint.yml` included in scaffold
  - Runs ESLint on PRs
  - Fails builds on linting errors
  - Configurable linting rules

**US-019**: As a **developer**, I want to see estimated GKE costs before deployment, so that I can make informed decisions about resource usage.
- **Acceptance Criteria**:
  - Cost estimation during `make deploy`
  - Monthly cost breakdown by service
  - Warnings for expensive configurations

---

## 4. Functional Requirements

### 4.1 Core Functionality (P0)

#### FR-001: Single-Command Local Environment
- **Requirement**: `make dev` command must start all services in correct order
- **Specifications**:
  - Docker Compose orchestrates: frontend, backend, Postgres, Redis
  - Automatic port allocation (3000, 8080, 5432, 6379)
  - Volume mounts for code hot reload
  - Health checks for each service
  - Network configuration for inter-service communication
  - Startup completes when all services report healthy

#### FR-002: Repository Configuration Discovery
- **Requirement**: Automatically detect project structure and requirements
- **Specifications**:
  - Parse `package.json` for React and Node.js detection
  - Scan for conventional folders: `/frontend`, `/backend`
  - Locate `schema.prisma` at `backend/prisma/schema.prisma`
  - Allow override paths in `config.yaml`
  - Validate detected configuration

#### FR-003: Empty Repository Scaffolding
- **Requirement**: Generate basic "hello world" project structure for new projects
- **Specifications**:
  - Detect empty target repository
  - Generate frontend: React + Vite + TypeScript + Tailwind CSS (basic structure)
  - Generate backend: Express + TypeScript + Prisma (basic structure)
  - Create example Prisma schema (User, Task models)
  - Include pre-commit hooks (Husky + lint-staged) for ESLint
  - Include GitHub Actions workflow (`.github/workflows/lint.yml`) for linting
  - **Note**: Full example task list application is provided separately as `example-task-app` repository

#### FR-004: Database Migration Management
- **Requirement**: Automatically run database migrations during setup
- **Specifications**:
  - Execute Prisma migrations automatically on `make dev` startup
  - Log migration status
  - Handle migration failures gracefully (stop startup with clear error)
  - No separate migration command needed (auto-run is sufficient)

#### FR-005: Smart Data Seeding
- **Requirement**: Generate realistic fake data from database schema
- **Specifications**:
  - `make seed` command triggers seeding
  - Introspect Prisma schema to understand models
  - Use Faker.js for data generation:
    - `email` → faker.internet.email()
    - `name` → faker.person.fullName()
    - `createdAt` → faker.date.recent()
  - Respect unique constraints
  - Handle foreign key relationships
  - Configurable seed counts in `config.yaml`
  - Default: 30 users, 5-10 tasks per user
  - Idempotent execution

#### FR-006: Hot Reload Support
- **Requirement**: Enable hot reload for frontend and backend
- **Specifications**:
  - Frontend: Vite HMR (Hot Module Replacement)
  - Backend: tsx watch for TypeScript file watching
  - Volume mounts for source code
  - Preserve application state during reload
  - Fast feedback loop (< 2 seconds)

#### FR-007: Health Check System
- **Requirement**: Verify all services are operational
- **Specifications**:
  - Each service exposes `/health` endpoint
  - Backend also exposes `/health/ready` endpoint (K8s readiness probe)
  - Health checks return simple JSON: `{status: "ok"}`
  - Startup script polls health endpoints
  - Environment marked "ready" only when all checks pass
  - Failed checks display actionable error messages

#### FR-008: GKE Deployment
- **Requirement**: Deploy application to Google Kubernetes Engine
- **Specifications**:
  - `make deploy` deploys via Kubernetes manifests
  - Terraform provisions GKE cluster (if needed)
  - Check for existing cluster, reuse if available
  - Configuration via `config.yaml`:
    - GCP project ID
    - Region (default: us-central1)
    - Cluster name
    - Node count and machine type
  - Deploy: frontend, backend, Postgres StatefulSet, Redis
  - Expose frontend via LoadBalancer
  - Convert environment variables to K8s ConfigMaps/Secrets

#### FR-009: Secrets Management
- **Requirement**: Handle secrets securely in both environments
- **Specifications**:
  - Local: Mock secrets in `.env` file
  - Production: Convert to K8s Secrets
  - Automatic detection of sensitive keys (password, secret, key, token)
  - Never log or display secret values
  - Prompt for production values during deployment
  - Support for secret rotation

#### FR-010: Environment Teardown
- **Requirement**: Clean up environments completely
- **Specifications**:
  - `make destroy` removes all resources
  - Local: Stop Docker containers, remove volumes
  - GKE: Delete K8s resources, optionally destroy cluster
  - Confirmation prompt before destructive operations
  - Display cost savings from teardown

### 4.2 Enhanced Functionality (P1)

#### FR-011: Service Dependency Management
- Dependencies start in correct order
- Health-based readiness checks
- Retry logic for transient failures

#### FR-012: Logging and Monitoring
- Structured JSON logs
- Log aggregation via `make logs`
- Service-specific log filtering

#### FR-013: Error Handling
- Port conflict detection and resolution
- Missing dependency detection
- Network troubleshooting assistance

---

## 5. Non-Functional Requirements

### 5.1 Performance
- **NFR-001**: Local environment startup must complete in < 10 minutes
- **NFR-002**: GKE deployment must complete in < 15 minutes
- **NFR-003**: Hot reload feedback loop must be < 2 seconds
- **NFR-004**: Health checks must respond in < 500ms

### 5.2 Reliability
- **NFR-005**: First-time setup success rate > 95%
- **NFR-006**: Idempotent operations (can run multiple times safely)
- **NFR-007**: Graceful degradation on partial failures

### 5.3 Security
- **NFR-008**: Secrets never committed to version control
- **NFR-009**: Mock credentials only in local environment
- **NFR-010**: Production secrets use K8s Secret resources
- **NFR-011**: Database passwords hashed with bcrypt (minimum 10 rounds)

### 5.4 Usability
- **NFR-012**: Single command to start environment (`make dev`)
- **NFR-013**: Clear, actionable error messages
- **NFR-014**: Comprehensive documentation (< 10 minute read)
- **NFR-015**: Zero DevOps expertise required for basic usage

### 5.5 Maintainability
- **NFR-016**: Infrastructure as Code (Terraform for GKE)
- **NFR-017**: Version-controlled configurations
- **NFR-018**: Modular architecture for future enhancements

### 5.6 Scalability
- **NFR-019**: Support for 4-10 microservices
- **NFR-020**: Database handles 100k+ rows efficiently
- **NFR-021**: GKE cluster scales to 10 nodes

---

## 6. Testing Requirements

### 6.1 Testing Strategy

#### Unit Tests
- Prisma model validations
- API endpoint logic
- Faker.js data generation functions
- Configuration parsing and validation

#### Integration Tests
- Service-to-service communication (frontend → backend → database)
- API endpoints with database operations
- Redis caching functionality
- Authentication flow (login, JWT validation, logout)

#### End-to-End Tests
- Full `make dev` workflow
- Scaffolding generation for empty repository
- `make seed` data generation
- `make deploy` to GKE
- `make destroy` cleanup

#### Health Check Tests
- Each service `/health` endpoint
- Database connectivity
- Redis connectivity
- Service startup ordering

### 6.2 Test Coverage Requirements
- **Backend**: 70% code coverage minimum
- **Frontend**: 60% code coverage minimum
- **Critical Paths**: 90% coverage (auth, deployment, seeding)

### 6.3 Test Environments
- Local: Docker Compose environment
- CI/CD: GitHub Actions with Docker
- Staging: GKE cluster (ephemeral)

---

## 7. Success Criteria

### 7.1 Launch Criteria
- [ ] `make dev` completes successfully on macOS, Linux, Windows (WSL2)
- [ ] Empty repository scaffolding generates working application
- [ ] Database seeding produces 30+ users with realistic data
- [ ] Hot reload works for frontend and backend
- [ ] All health checks pass within 5 minutes of startup
- [ ] `make deploy` successfully deploys to GKE
- [ ] `make destroy` cleanly removes all resources
- [ ] Documentation covers all common use cases
- [ ] Basic integration tests pass

### 7.2 Success Metrics (90 Days Post-Launch)
- Average setup time < 10 minutes (measured via telemetry)
- 95% first-time setup success rate
- 90% reduction in environment-related support tickets
- 50+ GitHub stars (community validation)
- 10+ external contributors

---

## 8. Demo Script

Detailed demonstration scripts with expected outputs and step-by-step walkthroughs are provided in a separate document: **DEMO_SCRIPT.md**

The demo document covers:
- New Developer Onboarding (15-minute walkthrough)
- Empty Repository Scaffolding (10-minute walkthrough)
- Expected command outputs and visual results

---

## 9. Dependencies & Assumptions

### 9.1 External Dependencies
- Docker Desktop installed (Mac/Windows) or Docker Engine (Linux)
- Git installed
- Google Cloud account with billing enabled (for GKE deployment)
- `gcloud` CLI installed and authenticated (for GKE deployment)
- `kubectl` installed (for GKE deployment)
- Terraform installed (for GKE cluster provisioning)

### 9.2 Technical Assumptions
- Developers have basic command-line proficiency
- Mono-repository structure (frontend + backend in one repo)
- Internet connectivity for downloading dependencies
- Minimum 8GB RAM, 20GB disk space available
- Modern browser (Chrome, Firefox, Safari, Edge)

### 9.3 Business Assumptions
- Developers are willing to adopt containerized workflows
- Teams value faster onboarding over custom environment control
- GKE costs are acceptable for staging/development environments

---

## 10. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Docker not installed | High | Medium | Clear error message with installation instructions |
| Port conflicts (3000, 8080) | Medium | High | Automatic port detection, suggest alternatives |
| GKE quota limits | High | Low | Document quota requirements, pre-deployment validation |
| Network/firewall issues | Medium | Medium | Offline mode for local-only development |
| Complex project structures | Medium | Medium | Prioritize conventional layouts, provide override options |
| Cost overruns (GKE left running) | High | Medium | Prominent teardown instructions, cost warnings |

---

## 11. Open Questions

1. Should the tool support Windows natively, or require WSL2?
2. Should `make deploy` support multiple GKE environments (dev, staging, prod)?
3. Should database backups be included in teardown process?
4. Should the tool integrate with CI/CD systems (GitHub Actions, GitLab CI)?
5. Should there be a web UI for configuration instead of YAML editing?

---

## 12. Appendix

### 12.1 Glossary
- **Hot Reload**: Automatic code reloading without manual restart
- **Health Check**: API endpoint that reports service status
- **Scaffolding**: Auto-generation of project structure
- **Seed Data**: Fake data for testing and development
- **Environment Parity**: Identical configuration between local and production

### 12.2 References
- Docker Compose Documentation: https://docs.docker.com/compose/
- Kubernetes Documentation: https://kubernetes.io/docs/
- Google Kubernetes Engine: https://cloud.google.com/kubernetes-engine
- Prisma Documentation: https://www.prisma.io/docs/
- Faker.js Documentation: https://fakerjs.dev/

---

**Document Status**: Ready for stakeholder review and technical specification development.
