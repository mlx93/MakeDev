# Pre-Deployment Checklist for GKE

## ✅ What You Need Before Running `make deploy`

### 1. GCP Account Setup (REQUIRED - Manual Setup)

**Important:** Having a Gmail account ≠ Having a GCP account

**Initial GCP Account Setup (One-Time):**
1. Go to https://console.cloud.google.com
2. Sign in with your Gmail account
3. Accept Google Cloud Terms of Service
4. Set up billing (required for GKE):
   - Click "Billing" in left menu
   - Create billing account
   - Add payment method (credit card)
5. Create a GCP Project:
   - Click "Select a Project" dropdown
   - Click "New Project"
   - Name it (e.g., "my-dev-cluster")
   - Copy the Project ID (NOT the project name)

**Our scripts DO NOT create GCP accounts or projects** - this must be done manually first.

### 2. Update config.yaml (REQUIRED)

```bash
cd example-task-app
nano config.yaml  # or use your preferred editor
```

**Update this line:**
```yaml
gke:
  project_id: "your-actual-gcp-project-id"  # Replace with your project ID from step 1
```

**Optional settings (have smart defaults):**
```yaml
gke:
  project_id: "my-gcp-project-123"  # REQUIRED
  region: "us-central1"              # Optional (default: us-central1)
  cluster_name: ""                   # Optional (default: <project-name>-cluster)
```

**Example from example-task-app:**
```yaml
# Zero-to-Running Developer Environment
# Example Task App Configuration

project:
  name: "task-app"              # Will create cluster: task-app-cluster
  git_repo: ""                  # Auto-filled by script

services:
  frontend:
    path: "./frontend"
    port: 3000
  backend:
    path: "./backend"
    port: 8080
  database:
    schema_path: "./backend/prisma/schema.prisma"
  cache:
    enabled: true

gke:
  project_id: "makedev-mlx"     # ← Your actual GCP project ID
  region: "us-central1"         # ← Default region
  cluster_name: ""              # ← Auto-generated: task-app-cluster

seed:
  users: 30
  tasks_per_user: "5-10"
```

### 3. Environment Variables (OPTIONAL)

The deployment will work with defaults, but for production you should create `.env.production`:

```bash
cd example-task-app
cp .env.example .env.production
nano .env.production
```

**Update passwords:**
- `DATABASE_PASSWORD` - Use a strong password
- `JWT_SECRET` - Generate a random secret (e.g., `openssl rand -base64 32`)

**If you skip this:** Defaults will be used (postgres/postgres) - fine for testing!

### 4. Prerequisites (AUTO-HANDLED)

These tools will be checked/installed automatically:
- ✅ Docker (should already be installed for `make dev`)
- ✅ Node.js 20+ (should already be installed)
- ✅ gcloud CLI (script will prompt to install)
- ✅ kubectl (script will prompt to install)
- ✅ terraform (script will prompt to install)
- ✅ GitHub CLI (auto-installed if missing)

**You will need to:**
- Run `gcloud auth login` when prompted
- Run `gh auth login` when prompted (for GitHub)

### 5. Cost Awareness

**Monthly GKE costs (~$68-73/month):**
- 2x e2-medium nodes: ~$48/month
- LoadBalancer: ~$18/month
- Storage (10GB): ~$2/month

**Remember:** Run `make destroy` when done to avoid charges!

## 🚀 Ready to Deploy!

Once you've completed steps 1-2 above (GCP project + config.yaml), run:

```bash
make deploy SUBDIR=example-task-app
```

The script will:
1. Check prerequisites (prompt to install missing tools)
2. Authenticate with GCP (prompt for `gcloud auth login`)
3. Set up GitHub repo (auto-install gh CLI if needed)
4. Provision GKE cluster (5-10 minutes)
5. Build and push Docker images
6. Deploy all services
7. Display your live URL!

## ❓ Troubleshooting

### "Project not found" error
- Make sure you created the project in GCP Console
- Use the Project **ID** (not name) in config.yaml
- Run `gcloud projects list` to see your projects

### "Billing not enabled" error
- Go to https://console.cloud.google.com/billing
- Enable billing on your project

### "Insufficient quota" error
- New GCP accounts have limited quotas
- Request quota increase in GCP Console
- Or try a different region

### GitHub CLI authentication fails
- Run `gh auth login` manually first
- Choose "GitHub.com" and follow prompts

