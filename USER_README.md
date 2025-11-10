# Zero-to-Running Developer Environment

**One command to go from zero to a fully running multi-service development environment.**

---

## Quick Start

```bash
# 1. Clone this repository into your project
git clone https://github.com/wander/zero-to-running-dev-env.git
cd zero-to-running-dev-env

# 2. Copy and configure
cp config.yaml.example config.yaml
# Edit config.yaml with your project details (e.g., git_repo: https://github.com/myorg/task-app.git)

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

That's it! Just 4 commands to go from zero to running to deployed.

---

## Configuration

Edit `config.yaml` to customize:

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

## URLs

After running `make dev`:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Health Check**: http://localhost:8080/health

---

## Troubleshooting

**Port conflicts?** Change ports in `config.yaml`:
```yaml
services:
  frontend:
    port: 3001  # Changed from 3000
```

**Docker not running?** Open Docker Desktop and wait for "running" status.

**Need help?** Check `docs/TROUBLESHOOTING.md` or open an issue.

---

## What Gets Created?

### Local (Docker Compose)
- React frontend (port 3000)
- Express backend (port 8080)
- PostgreSQL database (port 5432)
- Redis cache (port 6379)
- Hot reload enabled for frontend & backend

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

## Examples

### New Project (Scaffolding)
```bash
# config.yaml
project:
  name: task-app
  git_repo: ""  # Empty = scaffold new project

make dev  # Generates complete React + Node.js app
```

### Existing Project
```bash
# config.yaml
project:
  name: task-app
  git_repo: https://github.com/myorg/task-app.git

make dev  # Clones repo and starts services
```

### Deploy to Production
```bash
# config.yaml
project:
  name: task-app
gke:
  project_id: "my-gcp-project"

make deploy  # Provisions GKE, builds images, deploys
```

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

