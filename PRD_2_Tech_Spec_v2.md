# Zero-to-Running Developer Environment
## Technical Specification Document (Condensed)

**Version:** 1.0  
**Last Updated:** November 10, 2025  
**Document Type:** Technical Specification  
**Status:** Ready for Implementation

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Machine                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Zero-to-Running Dev Tool                     │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │  Makefile Orchestration Layer              │     │   │
│  │  │  - make dev    → Docker Compose            │     │   │
│  │  │  - make seed   → Seed Generator            │     │   │
│  │  │  - make deploy → Terraform + Kubectl       │     │   │
│  │  │  - make destroy→ Cleanup Scripts           │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │  Configuration Management                  │     │   │
│  │  │  - config.yaml     (user config)           │     │   │
│  │  │  - .env            (local secrets)         │     │   │
│  │  │  - schema.prisma   (database schema)       │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Local Development (Docker Compose)           │   │
│  │                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────┐ │   │
│  │  │ Frontend │  │ Backend  │  │Postgres  │  │Redis│ │   │
│  │  │  React   │→ │ Node.js  │→ │          │  │     │ │   │
│  │  │  :3000   │  │  :8080   │  │  :5432   │  │:6379│ │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────┘ │   │
│  │       ↓              ↓              ↓          ↓     │   │
│  │  [Volume Mounts for Hot Reload & Persistence]       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ make deploy
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Google Kubernetes Engine (GKE)                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Kubernetes Cluster                                  │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │  LoadBalancer (External IP)                │     │   │
│  │  │           ↓                                │     │   │
│  │  │  ┌──────────────────────────────┐          │     │   │
│  │  │  │   Frontend Deployment        │          │     │   │
│  │  │  │   (React, 2 replicas)        │          │     │   │
│  │  │  └──────────┬───────────────────┘          │     │   │
│  │  │             │ ClusterIP Service            │     │   │
│  │  │             ↓                              │     │   │
│  │  │  ┌──────────────────────────────┐          │     │   │
│  │  │  │   Backend Deployment         │          │     │   │
│  │  │  │   (Node.js, 2 replicas)      │          │     │   │
│  │  │  └──────────┬────────────┬──────┘          │     │   │
│  │  │             │            │                 │     │   │
│  │  │    ┌────────┘            └────────┐        │     │   │
│  │  │    ↓                              ↓        │     │   │
│  │  │  ┌──────────────┐      ┌──────────────┐   │     │   │
│  │  │  │  Postgres    │      │    Redis     │   │     │   │
│  │  │  │ StatefulSet  │      │  Deployment  │   │     │   │
│  │  │  │ (1 replica)  │      │  (1 replica) │   │     │   │
│  │  │  └──────────────┘      └──────────────┘   │     │   │
│  │  │         ↓                      ↓          │     │   │
│  │  │  [Persistent Volume]   [No persistence]  │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Repository Structure (Abbreviated)

```
zero-to-running-dev-env/          # Tool repository
├── Makefile                       # Primary orchestration
├── config.yaml.example            # Configuration template
├── README.md                      # Quick start guide
│
├── docker/                        # Docker configurations
│   ├── docker-compose.yml         # Local services definition
│   ├── Dockerfile.frontend        # Frontend multi-stage build
│   └── Dockerfile.backend         # Backend multi-stage build
│
├── k8s/                           # Kubernetes manifests
│   ├── frontend/                  # Frontend K8s resources
│   ├── backend/                   # Backend K8s resources
│   ├── postgres/                  # PostgreSQL StatefulSet
│   └── redis/                     # Redis Deployment
│
├── terraform/                     # GKE infrastructure
│   ├── main.tf                    # Cluster provisioning
│   ├── variables.tf               # Input variables
│   └── outputs.tf                 # Cluster outputs
│
├── scripts/                       # Automation scripts
│   ├── setup-local.sh             # Local environment setup
│   ├── scaffold-project.sh        # Project generation
│   ├── seed-database.ts           # Seed data generator
│   └── deploy-gke.sh              # GKE deployment automation
│
└── scaffold-templates/            # Project templates
    ├── frontend/                  # React/Tailwind scaffold
    └── backend/                   # Node.js/Prisma scaffold
```

---

## 2. Technology Stack

### 2.1 Core Technologies

| Layer | Technology | Version | Justification |
|-------|-----------|---------|---------------|
| **Container Runtime** | Docker | 24+ | Industry standard |
| **Local Orchestration** | Docker Compose | 2.23+ | Multi-container simplicity |
| **Cloud Orchestration** | Kubernetes | 1.28+ | Production-grade |
| **Cloud Platform** | GKE | Latest | Managed K8s |
| **IaC** | Terraform | 1.6+ | Infrastructure provisioning |

### 2.2 Application Stack

**Frontend**: React 18.2, Vite 5.0, TypeScript 5.3, Tailwind CSS 3.4, Axios 1.6, React Router 6.20  
**Backend**: Node.js 20 LTS, Express 4.18, TypeScript 5.3, Prisma 5.7, JWT 9.0, bcrypt 5.1, Zod 3.22  
**Database**: PostgreSQL 16, Prisma Client  
**Cache**: Redis 7.2, ioredis 5.3  
**Dev Tools**: ESLint 8.56, Prettier 3.1, tsx 4.7 (hot reload), Faker.js 8.3

---

## 3. Database Schema (Prisma)

### 3.1 Core Models

**User Model:**
- Fields: id (Int, PK), email (String, unique), name (String), password (String, bcrypt), timestamps
- Relations: One-to-Many with Task
- Indexes: email

**Task Model:**
- Fields: id (Int, PK), title (String), description (String?), status (enum), priority (enum), dueDate (DateTime?), userId (Int, FK), timestamps
- Relations: Many-to-One with User (cascade delete)
- Indexes: userId, status, dueDate
- Enums: TaskStatus (TODO, IN_PROGRESS, DONE, ARCHIVED), Priority (LOW, MEDIUM, HIGH, URGENT)

### 3.2 Migration Strategy

**Approach**: Prisma Migrate
- Migrations auto-run on `make dev` startup
- Manual execution via `make migrate` command
- Versioned migrations in `prisma/migrations/`
- Schema source of truth: `schema.prisma`

---

## 4. Backend API Specification (Condensed)

### 4.1 Base Configuration

**Base URL**: `http://localhost:8080/api/v1` (local) or `http://<lb-ip>/api/v1` (GKE)  
**Auth**: JWT Bearer tokens in `Authorization` header  
**Response Format**: JSON with `{success, data, message}` or `{success, error}`

### 4.2 Endpoint Summary

#### Authentication Endpoints
- `POST /auth/register` - Create new user account (email, name, password) → Returns user + JWT
- `POST /auth/login` - Authenticate user (email, password) → Returns user + JWT
- `GET /auth/me` - Get current user profile (requires auth) → Returns user object

**Key Logic**:
- Password hashing: bcrypt with 10 rounds
- JWT expiration: 7 days
- Session storage: Redis
- Rate limiting: 5 login attempts per minute per IP

#### Task Endpoints (CRUD)
- `GET /tasks` - List all user's tasks (auth required)
  - Query params: status, priority, sort, order, limit, offset
  - Returns: Array of tasks with pagination metadata
  
- `GET /tasks/:id` - Get single task (auth required)
  - Returns: Task object or 404
  
- `POST /tasks` - Create new task (auth required)
  - Body: title (required), description, priority, dueDate
  - Returns: Created task object
  
- `PATCH /tasks/:id` - Update task (auth required)
  - Body: Any task fields (partial update)
  - Returns: Updated task object
  
- `DELETE /tasks/:id` - Delete task (auth required)
  - Returns: Success message

#### Health Endpoints
- `GET /health` - Service health (no auth)
  - Returns: Status, timestamp, service statuses (database, redis), version
  
- `GET /health/ready` - Kubernetes readiness probe (no auth)
  - Returns: `{ready: true}` when all dependencies available

### 4.3 Error Handling

**Standard Error Codes**:
- 400: VALIDATION_ERROR (invalid input)
- 401: UNAUTHORIZED (invalid/missing JWT) or INVALID_CREDENTIALS
- 404: RESOURCE_NOT_FOUND (task/user not found)
- 409: CONFLICT (duplicate email)
- 429: RATE_LIMITED (too many requests)
- 500: INTERNAL_ERROR (server error)

---

## 5. Frontend Architecture (Condensed)

### 5.1 Component Hierarchy

```
App.tsx (Router + AuthContext)
├── LoginPage
│   └── LoginForm
├── RegisterPage
│   └── RegisterForm
├── DashboardPage
│   ├── Layout (Header, Sidebar)
│   ├── TaskList
│   │   ├── TaskFilter
│   │   └── TaskItem (multiple)
│   └── TaskFormModal
└── NotFoundPage
```

### 5.2 State Management

**Authentication**: React Context with local storage persistence  
**API Communication**: Axios with request/response interceptors  
**Request Interceptor**: Add JWT to Authorization header  
**Response Interceptor**: Handle 401 errors (redirect to login)

### 5.3 Vite Configuration

**Dev Server**: Port 3000, hot module replacement enabled  
**Proxy**: `/api` requests proxied to `http://backend:8080` (avoids CORS)  
**Build**: Output to `dist/`, source maps enabled

---

## 6. Environment Configuration

### 6.1 Configuration File Schema (config.yaml)

```yaml
project:
  name: string                     # Project name
  git_repo: string                 # Repository URL (optional for scaffold)

services:                          # Optional - uses defaults if omitted
  frontend:
    path: ./frontend               # Default
    port: 3000                     # Default
  backend:
    path: ./backend                # Default
    port: 8080                     # Default
  database:
    type: postgres                 # Required
    schema_path: ./backend/prisma/schema.prisma  # Default
  cache:
    type: redis
    enabled: true                  # Optional

gke:
  create_cluster: boolean          # Create new or use existing
  project_id: string               # GCP project (required)
  region: string                   # Default: us-central1
  cluster_name: string             # Default: <project_name>-cluster
  node_config:
    machine_type: e2-medium        # Default
    node_count: 2                  # Default

seed:
  users: 30                        # Number of users
  tasks_per_user: "5-10"           # Range or fixed number
```

### 6.2 Environment Variables

**Local (.env)**:
```
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/appdb
REDIS_URL=redis://redis:6379
JWT_SECRET=local-dev-secret
API_PORT=8080
NODE_ENV=development
VITE_API_URL=http://localhost:8080/api/v1
```

**Production (K8s Secrets)**: Auto-converted from .env
- Sensitive keys detected: password, secret, key, token
- Stored as base64-encoded Kubernetes Secrets
- Mounted as environment variables in pods

---

## 7. Docker Configuration (Abbreviated)

### 7.1 Docker Compose Structure

**Services**: frontend, backend, postgres, redis  
**Networks**: Single bridge network for inter-service communication  
**Volumes**: 
- postgres-data (persistent)
- redis-data (persistent)
- Source code mounts for hot reload

**Health Checks**: All services define health check commands  
**Dependency Ordering**: Frontend depends on backend, backend depends on postgres + redis

### 7.2 Dockerfile Strategy

**Frontend**: Node 20 Alpine base, npm ci for dependencies, expose 3000, run Vite dev server  
**Backend**: Node 20 Alpine base, npm ci + Prisma generate, expose 8080, run migrations + tsx dev

**Production Build**: Multi-stage builds for smaller images (development layers removed)

---

## 8. Kubernetes Deployment (Abbreviated)

### 8.1 Resource Specifications

**Frontend Deployment**:
- Replicas: 2
- Container port: 3000
- Resources: 256Mi/100m (requests), 512Mi/500m (limits)
- Probes: Liveness (HTTP /), Readiness (HTTP /)
- Service: LoadBalancer on port 80

**Backend Deployment**:
- Replicas: 2
- Container port: 8080
- Resources: 512Mi/250m (requests), 1Gi/1000m (limits)
- Probes: Liveness (HTTP /health), Readiness (HTTP /health/ready)
- Service: ClusterIP on port 8080
- ConfigMaps & Secrets: Environment variables

**PostgreSQL StatefulSet**:
- Replicas: 1
- Container port: 5432
- Resources: 512Mi/250m (requests), 1Gi/500m (limits)
- Storage: 10Gi Persistent Volume
- Service: ClusterIP on port 5432

**Redis Deployment**:
- Replicas: 1
- Container port: 6379
- Resources: 256Mi/100m (requests), 512Mi/250m (limits)
- No persistent storage (cache only)
- Service: ClusterIP on port 6379

---

## 9. Terraform Infrastructure (Pseudo-Structure)

### 9.1 GKE Cluster Provisioning Logic

```hcl
# Pseudo-code representation

PROVIDER: Google Cloud
REGION: var.gcp_region (default: us-central1)
ZONE: var.gcp_zone (default: us-central1-a)

RESOURCE: google_container_cluster
  - Name: var.cluster_name
  - Location: var.gcp_zone
  - Remove default node pool: true
  - Initial node count: 1 (temporary)
  - Workload Identity: enabled
  - Logging/Monitoring: Kubernetes engine services

RESOURCE: google_container_node_pool
  - Name: ${cluster_name}-node-pool
  - Node count: var.node_count (default: 2)
  - Machine type: var.machine_type (default: e2-medium)
  - Disk size: var.disk_size_gb (default: 20)
  - Auto-repair: enabled
  - Auto-upgrade: enabled
  - OAuth scopes: cloud-platform
```

### 9.2 Variables

**Required**: gcp_project_id, cluster_name  
**Optional with defaults**: gcp_region, gcp_zone, node_count, machine_type, disk_size_gb, environment

### 9.3 Outputs

- Cluster endpoint (API server URL)
- Cluster CA certificate
- Kubeconfig generation command

---

## 10. Seed Data Generator (Logic Overview)

### 10.1 Seed Algorithm Pseudo-Code

```
FUNCTION generateSeeds(config):
  READ schema from config.schema_path
  PARSE models from Prisma schema
  
  FOR model in models:
    EXTRACT fields and types
    CREATE field_mapping:
      - "email" → faker.internet.email()
      - "name" → faker.person.fullName()
      - "createdAt" → faker.date.recent()
      - "description" → faker.lorem.paragraph()
      - "status" → random from enum values
      - "priority" → random from enum values
      - Foreign keys → reference previously created records
  
  CLEAR existing data (DELETE all records)
  
  GENERATE users:
    FOR i from 1 to config.seed.users:
      CREATE user with faker data
      HASH password with bcrypt
      STORE user reference
  
  GENERATE tasks:
    PARSE config.seed.tasks_per_user (e.g., "5-10" → min=5, max=10)
    FOR user in users:
      task_count = RANDOM(min, max)
      FOR i from 1 to task_count:
        CREATE task with faker data
        ASSIGN task.userId = user.id
  
  RETURN summary (users created, tasks created, execution time)
```

### 10.2 Smart Field Detection

**Type Inference**:
- `email` field → Generate valid email addresses
- `name` / `firstName` / `lastName` → Generate realistic names
- `phone` → Generate phone numbers
- `address` / `city` / `country` → Generate location data
- `date` / `createdAt` / `updatedAt` → Generate recent timestamps
- `description` / `bio` / `content` → Generate paragraph text
- Enum types → Random selection from valid enum values
- Foreign keys → Reference existing parent records

**Constraints Handling**:
- `@unique` → Ensure no duplicates (use Faker unique API)
- `@default` → Use specified default or Faker equivalent
- Optional fields (`?`) → 70% filled, 30% null (configurable)
- Required fields → Always generate value

---

## 11. Makefile Command Reference

```makefile
help       # Display available commands with descriptions
dev        # Start local development environment (Docker Compose up)
seed       # Generate fake data from Prisma schema
deploy     # Deploy to GKE (Terraform + kubectl apply)
destroy    # Teardown all resources (local + GKE)
clean      # Remove Docker containers and volumes
logs       # Tail logs from all services
status     # Check health status of all services
migrate    # Run Prisma migrations manually
```

### 11.1 Command Workflow

**make dev**: 
1. Check Docker installation
2. Read config.yaml
3. Clone/detect repository
4. If empty → scaffold-project.sh
5. Build Docker images
6. Docker Compose up
7. Wait for health checks
8. Run migrations
9. Display URLs

**make deploy**:
1. Authenticate with GCP
2. Check for existing cluster
3. If not exists → Terraform apply (provision cluster)
4. Build production images
5. Push images to Artifact Registry
6. kubectl apply -f k8s/
7. Wait for pods ready
8. Get LoadBalancer IP
9. Display URL + cost estimate

**make destroy**:
1. Prompt for confirmation
2. Docker Compose down -v (local)
3. kubectl delete -f k8s/ (GKE resources)
4. Optionally: Terraform destroy (cluster)
5. Clean Terraform state
6. Display cost savings

---

## 12. Development Workflow Diagrams

### 12.1 Initial Setup Flow
```
Clone Tool → Edit config.yaml → make dev →
  ↓
Detect repo state (empty vs existing) →
  ↓
Empty: Generate scaffold | Existing: Clone code →
  ↓
Build images → Start services → Run migrations →
  ↓
Health checks → Environment ready!
```

### 12.2 Daily Development Flow
```
Start work → make dev (if not running) →
  ↓
Edit code → Hot reload applies changes →
  ↓
Test in browser → Repeat →
  ↓
Commit → Push → make deploy (when ready)
```

### 12.3 GKE Deployment Flow
```
make deploy → Check cluster exists →
  ↓
No: Terraform provision | Yes: Skip →
  ↓
Build images → Push to Artifact Registry →
  ↓
Apply K8s manifests → Wait for pods →
  ↓
Get LoadBalancer IP → Display URL + costs
```

---

## 13. Integration Points

### 13.1 External Integrations
- **GitHub**: HTTPS/SSH repository cloning
- **Google Cloud**: GKE, Artifact Registry, Cloud Logging/Monitoring
- **Docker**: Local container runtime
- **NPM**: Package management for Node.js

### 13.2 Service Communication
- **Frontend → Backend**: HTTP/HTTPS via Vite proxy (local) or direct (GKE)
- **Backend → PostgreSQL**: TCP on port 5432 (Prisma connection)
- **Backend → Redis**: TCP on port 6379 (ioredis client)
- **Kubernetes Services**: ClusterIP for internal, LoadBalancer for external

---

## 14. Security Considerations

### 14.1 Secret Management
- **Local**: .env file (gitignored), mock secrets only
- **GKE**: Kubernetes Secrets (base64-encoded, encrypted at rest)
- **Password Hashing**: bcrypt with 10+ rounds
- **JWT**: HS256 algorithm, 7-day expiration
- **Never**: Log secrets, commit to git, embed in images

### 14.2 Network Security
- **Backend**: Not exposed publicly (ClusterIP service)
- **Database/Redis**: Internal only (ClusterIP services)
- **Frontend**: Public via LoadBalancer
- **Authentication**: Required for all non-public endpoints

---

## 15. Monitoring & Observability

### 15.1 Health Checks
- All services expose `/health` endpoints
- Docker Compose: HEALTHCHECK directives
- Kubernetes: Liveness and readiness probes
- Startup validation before marking environment ready

### 15.2 Logging
- **Local**: Docker Compose logs (`docker-compose logs -f`)
- **GKE**: Automatic Cloud Logging integration
- **Format**: JSON structured logs in production, human-readable in dev

### 15.3 Metrics
- Basic health status endpoints
- GKE built-in monitoring dashboards
- No custom metrics in initial version (future enhancement)

---

## 16. Cost Estimates

### 16.1 GKE Monthly Costs (Default Configuration)
- **Cluster Management**: Free (GKE managed control plane)
- **Compute (2 x e2-medium)**: ~$48/month
- **Load Balancer**: ~$18/month
- **Persistent Disk (10GB)**: ~$2/month
- **Estimated Total**: $68-73/month

**Cost Optimization**:
- Use `make destroy` when not needed
- Preemptible nodes for dev/staging (50% savings)
- Autopilot mode for dynamic scaling (pay-per-pod)

---

## 17. Implementation Priorities

### 17.1 Phase 1 (Week 1-2): Core Functionality
- Makefile commands (dev, deploy, destroy)
- Docker Compose setup
- Basic scaffolding generator
- Health checks

### 17.2 Phase 2 (Week 3-4): Advanced Features
- Seed data generator
- GKE Terraform provisioning
- K8s manifests and deployment
- Secret management

### 17.3 Phase 3 (Week 5-6): Polish & Documentation
- Error handling and validation
- Comprehensive documentation
- Demo scripts and examples
- Testing and bug fixes

---

**Document Status**: Ready for implementation. Refer to full technical specification for complete code examples and detailed configurations.
