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

