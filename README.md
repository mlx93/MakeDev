# Zero-to-Running Developer Environment

**One command to go from zero to a fully running multi-service development environment.**

---

## Quick Start

**Option 1: Create a new project in a subdirectory (recommended)**
```bash
# 1. Clone this repository
git clone https://github.com/wander/zero-to-running-dev-env.git
cd zero-to-running-dev-env

# 2. Create and start a new project
make dev SUBDIR=my-app
```

**Option 2: Use from tool root**
```bash
# 1. Clone this repository
git clone https://github.com/wander/zero-to-running-dev-env.git
cd zero-to-running-dev-env

# 2. Copy and configure
cp config.yaml.example config.yaml
# Edit config.yaml with your project details

# 3. Start your environment
make dev
```

That's it! Your frontend, backend, database, and cache are now running.

---

## Prerequisites

**macOS only** (for now)

Before running `make dev`, ensure you have:
- **Docker Desktop** installed and running
- **Node.js 20+** installed

If missing, `make dev` will show you one-line install commands.

For `make deploy` (GKE), you'll also need:
- **Google Cloud SDK** (`gcloud`)
- **kubectl**
- **Terraform**

---

## Commands

**Core Commands (4 total):**

```bash
make dev      # Start all services (frontend, backend, postgres, redis)
make seed     # Generate fake data for testing
make deploy   # Deploy to Google Kubernetes Engine
make destroy  # Teardown all resources (local + GKE)
```

---

## Configuration

Edit `config.yaml` to customize your project:

```yaml
project:
  name: task-app
  git_repo: https://github.com/myorg/task-app.git  # Optional: leave empty to scaffold

gke:
  project_id: "your-gcp-project-id"  # Required for make deploy
  region: us-central1
```

See `config.yaml.example` for all options.

---

## URLs

After running `make dev`:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Health Check**: http://localhost:8080/api/v1/health

---

## Project Structure

The tool expects this structure (or uses config.yaml overrides):

```
your-project/
├── frontend/          # React + Vite + TypeScript
├── backend/           # Express + TypeScript + Prisma
│   └── prisma/
│       └── schema.prisma
└── .env               # Environment variables (gitignored)
```

**Don't have a project yet?** Leave `git_repo` empty in config.yaml and the tool will scaffold a complete app for you!

---

## Environment Variables

Create `.env` in your project root:

```bash
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/appdb
REDIS_URL=redis://redis:6379
JWT_SECRET=your-secret-here
VITE_API_URL=http://localhost:8080/api/v1
```

For production (GKE), create `.env.production` (falls back to `.env` if missing).

---

## `make dev` Execution Paths & Examples

The `make dev` command intelligently handles different scenarios based on your project state. Each path includes example `config.yaml` configurations:

### 1. Create New Project in Subdirectory (Recommended)

**Command:**
```bash
make dev SUBDIR=my-app
```

**What happens:**
- Creates `my-app/` directory if it doesn't exist
- Bootstraps tool infrastructure (docker/, scripts/, Makefile)
- Creates `config.yaml` with `git_repo: ""` (triggers scaffolding)
- Scaffolds a complete "hello world" app
- Builds and starts all services

**Example config.yaml** (auto-created):
```yaml
project:
  name: my-app
  git_repo: ""  # Empty = scaffold new project
```

---

### 2. Existing Empty Subdirectory

**Command:**
```bash
make dev SUBDIR=my-app  # my-app/ exists but is empty
```

**What happens:**
- Detects empty folder (no `config.yaml`, `frontend/`, or `backend/`)
- Bootstraps tool infrastructure if missing
- Creates `config.yaml` with `git_repo: ""` (triggers scaffolding)
- Scaffolds a complete app
- Builds and starts all services

**Example config.yaml** (auto-created):
```yaml
project:
  name: my-app
  git_repo: ""  # Empty = scaffold new project
```

---

### 3. Standard Usage (from tool root) - New Project

**Command:**
```bash
make dev
```

**Example config.yaml:**
```yaml
project:
  name: task-app
  git_repo: ""  # Empty = scaffold new project
```

**What happens:**
- Reads `config.yaml` from current directory
- Detects empty `git_repo` → scaffolds a new "hello world" app
- Builds Docker images and starts all services

---

### 4. Standard Usage (from tool root) - Existing GitHub Project

**Command:**
```bash
make dev
```

**Example config.yaml:**
```yaml
project:
  name: task-app
  git_repo: https://github.com/myorg/task-app.git
```

**What happens:**
- Reads `config.yaml` from current directory
- Clones the repository (if not already cloned)
- Uses `frontend/` and `backend/` from cloned repo
- Creates symlinks if repo is in subdirectory
- Builds and starts all services

---

### 5. Existing Project with Code

**Command:**
```bash
make dev SUBDIR=my-app  # my-app/ has config.yaml or frontend/backend/
```

**Example config.yaml** (existing):
```yaml
project:
  name: my-app
  git_repo: ""  # Or: https://github.com/myorg/my-app.git
```

**What happens:**
- Reads existing `config.yaml`
- If `git_repo` is empty → scaffolds app (if not already scaffolded)
- If `git_repo` is set → clones repository (if not already cloned)
- Uses existing `frontend/` and `backend/` directories
- Builds and starts all services

---

### Common Behaviors (All Paths)

**Automatic Cleanup:**
- Frees port 5432 (PostgreSQL) if in use by Docker containers
- Frees port 6379 (Redis) if used by your project containers
- Stops and removes old containers matching your project name
- Runs `docker-compose down` if services are still running

**Idempotent Operations:**
- Safe to run `make dev` multiple times
- Reuses healthy containers if already running
- Only rebuilds if containers are unhealthy or missing

**Health Checks:**
- Waits for all services to be healthy before completing
- Shows progress with ✅/❌ indicators
- Times out after 5 minutes if services don't become healthy

---

### Deploy to Production

**Command:**
```bash
make deploy
```

**Example config.yaml:**
```yaml
project:
  name: task-app
  git_repo: https://github.com/myorg/task-app.git

gke:
  project_id: "my-gcp-project"
  region: us-central1
```

**What happens:**
- Provisions GKE cluster (or reuses existing)
- Builds Docker images
- Deploys all services to Kubernetes
- Creates LoadBalancer for frontend

---

## Troubleshooting

**Port conflicts?** The tool automatically frees ports 5432 and 6379 if they're in use by Docker containers. If you have a non-Docker service using these ports, stop it manually.

**Docker not running?** Open Docker Desktop and wait for "running" status.

**Containers unhealthy?** The tool automatically stops and removes unhealthy containers. Check logs with:
```bash
docker-compose -f docker/docker-compose.yml logs -f
```

**Need help?** Check `docs/` folder or open an issue.

---

## What Gets Created?

### Local (Docker Compose)
- React frontend (port 3000) with Vite HMR
- Express backend (port 8080) with tsx watch
- PostgreSQL database (port 5432)
- Redis cache (port 6379)
- Hot reload enabled for frontend & backend
- Automatic Prisma migrations on startup

### GKE (Production)
- GKE cluster (auto-provisioned or reused)
- Frontend LoadBalancer (public IP)
- Backend ClusterIP (internal only)
- PostgreSQL StatefulSet with persistent storage
- Redis deployment
- All secrets from `.env.production` or `.env`

---

## Cost Estimates

**GKE Deployment** (default config):
- ~$71/month (2 x e2-medium nodes + LoadBalancer)
- Run `make destroy` when not needed to avoid costs

---

## Documentation

See `docs/` folder for detailed documentation and setup instructions.

---

## License

MIT

---

## Support

- **Documentation**: See `docs/` folder
- **Issues**: GitHub Issues
- **Questions**: Open a discussion

---

**Happy coding!** 🚀

