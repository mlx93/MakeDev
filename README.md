# Zero-to-Running Developer Environment

**One command to go from zero to a fully running multi-service development environment.**

---

## Quick Start

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

### `make dev` Execution Paths

The `make dev` command intelligently handles different scenarios based on your project state:

#### 1. Standard Usage (from tool root)
```bash
make dev
```
**Path:** Runs from the tool repository root
- Reads `config.yaml` from current directory
- If `git_repo` is empty → scaffolds a new "hello world" app
- If `git_repo` is set → clones the repository
- Builds Docker images and starts all services

#### 2. Create New Project in Subdirectory
```bash
make dev SUBDIR=my-app
```
**Path:** Creates a new subdirectory and sets up a project
- Creates `my-app/` directory if it doesn't exist
- Bootstraps tool infrastructure (docker/, scripts/, Makefile)
- Creates `config.yaml` with `git_repo: ""` (triggers scaffolding)
- Scaffolds a complete "hello world" app
- Builds and starts all services

#### 3. Existing Empty Subdirectory
```bash
make dev SUBDIR=my-app  # my-app/ exists but is empty
```
**Path:** Treats empty folder as greenfield project
- Detects empty folder (no `config.yaml`, `frontend/`, or `backend/`)
- Bootstraps tool infrastructure if missing
- Creates `config.yaml` with `git_repo: ""` (triggers scaffolding)
- Scaffolds a complete app
- Builds and starts all services

#### 4. Existing Project with Code
```bash
make dev SUBDIR=my-app  # my-app/ has config.yaml or frontend/backend/
```
**Path:** Uses existing project configuration
- Reads existing `config.yaml`
- If `git_repo` is empty → scaffolds app (if not already scaffolded)
- If `git_repo` is set → clones repository (if not already cloned)
- Uses existing `frontend/` and `backend/` directories
- Builds and starts all services

#### 5. Project Connected to GitHub
```bash
make dev  # config.yaml has git_repo: "https://github.com/user/repo.git"
```
**Path:** Clones and uses GitHub repository
- Clones the repository (if not already cloned)
- Uses `frontend/` and `backend/` from cloned repo
- Creates symlinks if repo is in subdirectory
- Builds and starts all services

#### Common Behaviors (All Paths)

**Automatic Cleanup:**
- Frees port 5432 (PostgreSQL) if in use
- Frees port 6379 (Redis) if used by your project
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

## Configuration

Edit `config.yaml` to customize your project. See `config.yaml.example` for all options.

---

## URLs

After running `make dev`:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Health Check**: http://localhost:8080/health

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

## Documentation

Full documentation will be added by D&D agent.

---

## License

MIT

---

**Happy coding!** 🚀

