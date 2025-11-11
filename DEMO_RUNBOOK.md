# Zero-to-Running Developer Environment
## Demo Runbook

**Duration:** 5-6 minutes  
**Last Updated:** November 11, 2025  
**Purpose:** Copy-paste demo guide with expected outputs and timing

---

## Prerequisites Checklist

Before starting the demo, ensure:

- [ ] Docker Desktop is running (check menu bar)
- [ ] Terminal window ready
- [ ] Browser ready (Chrome/Firefox)
- [ ] Internet connection stable
- [ ] `config.yaml` prepared (or use interactive generator)

---

## Demo Scenario: New Developer Onboarding

**Goal:** Show complete setup from zero to running application in under 6 minutes.

---

## Step-by-Step Demo Script

### [0:00-0:30] Introduction

**Narration:**
> "Hi, I'm going to show you how a new developer can go from zero to a running application in under 6 minutes. This is Alex's first day. They've never seen our codebase, but they need to start contributing immediately."

---

### [0:30-1:00] Step 1: Clone Tool

**Command:**
```bash
git clone https://github.com/wander/zero-to-running-dev-env.git
cd zero-to-running-dev-env
```

**Expected Output:**
```
Cloning into 'zero-to-running-dev-env'...
remote: Enumerating objects: 1234, done.
remote: Counting objects: 100% (1234/1234), done.
remote: Compressing objects: 100% (567/567), done.
remote: Total 1234 (delta 456), reused 1234 (delta 456), pack-reused 0
Receiving objects: 100% (1234/1234), 2.34 MiB | 5.12 MiB/s, done.
Resolving deltas: 100% (456/456), done.
```

**Narration:**
> "First, Alex clones our developer environment tool. This tool will handle everything."

---

### [1:00-1:30] Step 2: Configure

**Option A: Interactive Config Generator (Recommended)**
```bash
make config SUBDIR=demo-app
```

**Expected Output:**
```
🔧 Interactive Configuration Generator

Project name [demo-app]: demo-app
GCP project ID: my-gcp-project
GCP region [us-central1]: us-central1
Cluster name [demo-app-cluster]: 
Machine type [e2-medium]: 
Node count [2]: 
Disk size (GB) [20]: 

✅ Configuration saved to demo-app/config.yaml
```

**Option B: Manual Config (Alternative)**
```bash
mkdir demo-app
cat > demo-app/config.yaml <<EOF
project:
  name: demo-app
  git_repo: ""

gke:
  project_id: "my-gcp-project"
  region: us-central1
EOF
```

**Narration:**
> "Alex only needs to configure this simple YAML file—project name and repository URL. That's it. No Docker expertise needed, no complex setup scripts."

---

### [1:30-3:30] Step 3: Start Environment (2 minutes)

**Command:**
```bash
make dev SUBDIR=demo-app
```

**Expected Output (Key Lines):**
```
🚀 Starting local development environment...
✓ Checking Docker installation
✓ Checking prerequisites...
✓ Reading configuration from demo-app/config.yaml
✓ Project name: demo-app
✓ Repository is empty, scaffolding new project...
✓ Creating frontend/ (React + TypeScript + Tailwind)
✓ Creating backend/ (Express + TypeScript + Prisma)
✓ Installing dependencies...
✓ Building Docker images...
✓ Starting PostgreSQL... healthy
✓ Starting Redis... healthy  
✓ Running database migrations... 3 migrations applied
✓ Starting backend API... healthy at http://localhost:8080
✓ Starting frontend... healthy at http://localhost:3000

🎉 Environment ready!
   Frontend: http://localhost:3000
   Backend API: http://localhost:8080/api
   Database: localhost:5432
```

**What to Look For:**
- ✅ All services show "healthy"
- ✅ Migrations applied successfully
- ✅ Frontend and backend URLs displayed
- ✅ No error messages

**Narration:**
> "Watch this—the tool is automatically:
> - Cloning the application repository (or scaffolding if empty)
> - Building Docker containers for all services
> - Starting PostgreSQL, Redis, backend API, and frontend
> - Running database migrations
> - Checking that everything is healthy
>
> All with one command. No manual steps."

---

### [3:30-4:00] Step 4: Seed Database

**Command:**
```bash
make seed SUBDIR=demo-app
```

**Expected Output:**
```
🌱 Seeding database with fake data...
✓ Reading Prisma schema from demo-app/backend/prisma/schema.prisma
✓ Generating 30 users...
✓ Generating 240 tasks (8 per user)...
✓ Seeding complete!

📊 Summary:
   Users created: 30
   Tasks created: 240
   Execution time: 2.3s

🔑 Demo credentials:
   Email: demo@example.com
   Password: demo123
```

**What to Look For:**
- ✅ Users and tasks created successfully
- ✅ Demo credentials displayed
- ✅ No errors

**Narration:**
> "Now let's populate the database with realistic test data. This generates 30 users and their tasks using smart fake data generation."

---

### [4:00-5:30] Step 5: Show Running Application

**Command:**
```bash
open http://localhost:3000
```

**Browser Demonstration Steps:**

1. **Show login page**
   - *"Here's our task application, fully running"*

2. **Login with demo credentials**
   - Email: `demo@example.com`
   - Password: `demo123`
   - Click "Login"
   - *"Authentication works with JWT tokens"*

3. **Show task list with 240 tasks**
   - *"All 240 tasks loaded from our seeded database"*
   - Show filtering by status
   - Show sorting options

4. **Add a new task**
   - Click "Add Task" button
   - Fill in: "Demo new feature"
   - Set priority: HIGH
   - Click "Create"
   - *"Watch—task instantly appears. That's a real API call to our backend, writing to PostgreSQL"*

5. **Mark a task as complete**
   - Click checkbox on a task
   - *"Status updates immediately"*

6. **Delete a task**
   - Click delete icon
   - *"Full CRUD operations working end-to-end"*

**Narration:**
> "The application is fully functional with authentication, task management, and real-time updates."

---

### [5:30-6:00] Step 6: Show Hot Reload (Optional)

**Command:**
```bash
# In another terminal (split screen)
cd demo-app/frontend/src
# Open TaskList.tsx in editor, change button text
# Save file
```

**Expected Behavior:**
- Browser updates automatically without refresh
- Changes visible in < 2 seconds

**Narration:**
> "I just changed the 'Add Task' button text. Watch the browser—it updated automatically without refresh. This works for both frontend and backend code."

---

### [6:00-6:30] Conclusion

**Narration:**
> "That's it! In 6 minutes, Alex went from nothing to a fully functional development environment with:
> - React frontend
> - Node.js backend API
> - PostgreSQL database
> - Redis cache
> - Real authentication
> - Hot reload for fast iteration
> - 240 realistic test records
>
> And when Alex is ready to deploy? One command: `make deploy` sends everything to Google Kubernetes Engine in production-ready containers."

---

## Golden Outputs

### Expected `make dev` Output (Success)

**Key Success Indicators:**
- ✅ All services show "healthy"
- ✅ Migrations applied
- ✅ URLs displayed
- ✅ No error messages

**Full Output Pattern:**
```
🚀 Starting local development environment...
✓ Checking Docker installation
✓ [Service]... healthy
🎉 Environment ready!
```

### Expected `make seed` Output (Success)

**Key Success Indicators:**
- ✅ Users and tasks created
- ✅ Demo credentials displayed
- ✅ Summary shows correct counts

**Full Output Pattern:**
```
🌱 Seeding database...
✓ Generating 30 users...
✓ Generating 240 tasks...
✓ Seeding complete!
🔑 Demo credentials: demo@example.com / demo123
```

### Expected `make deploy` Output (Success)

**Key Success Indicators:**
- ✅ Cluster provisioned or reused
- ✅ Images built and pushed
- ✅ Pods running
- ✅ LoadBalancer IP displayed

**Full Output Pattern:**
```
☁️  Deploying to Google Kubernetes Engine...
✓ Checking GCP authentication
✓ Checking for existing cluster... found (reusing)
✓ Building production Docker images...
✓ Pushing to Artifact Registry...
✓ Deploying services...
✓ Waiting for pods...
✓ Seed script running...

🎉 Deployment complete!
   Application: http://34.123.45.67
   Estimated monthly cost: $73
```

### Expected Health Check Responses

**Backend Health:**
```bash
curl http://localhost:8080/api/v1/health
```

**Response:**
```json
{"status":"ok"}
```

**Backend Readiness:**
```bash
curl http://localhost:8080/api/v1/health/ready
```

**Response:**
```json
{"status":"ok"}
```

---

## Fallback Steps

### If `make dev` Fails

1. **Check Docker:**
   ```bash
   docker ps
   ```
   - If error: Open Docker Desktop, wait for "running" status

2. **Check Ports:**
   ```bash
   lsof -i :3000 -i :8080 -i :5432 -i :6379
   ```
   - Stop conflicting services manually

3. **Check Logs:**
   ```bash
   docker-compose -f demo-app/docker/docker-compose.yml logs -f
   ```

### If `make seed` Fails

1. **Check Database:**
   ```bash
   curl http://localhost:8080/api/v1/health/ready
   ```
   - Should return `{"status":"ok"}`

2. **Check Prisma Schema:**
   ```bash
   ls demo-app/backend/prisma/schema.prisma
   ```
   - Ensure schema exists

### If Deployment Fails

1. **Check GCP Authentication:**
   ```bash
   gcloud auth list
   gcloud config get-value project
   ```

2. **Check Prerequisites:**
   ```bash
   gcloud --version
   kubectl version --client
   terraform --version
   ```

3. **See `PRE_DEPLOYMENT_CHECKLIST.md` for detailed setup**

---

## Timing Notes

**Target Timing (6 minutes):**
- Introduction: 0:00-0:30 (30s)
- Clone Tool: 0:30-1:00 (30s)
- Configure: 1:00-1:30 (30s)
- Start Environment: 1:30-3:30 (2m)
- Seed Database: 3:30-4:00 (30s)
- Show Application: 4:00-5:30 (1m30s)
- Hot Reload (Optional): 5:30-6:00 (30s)
- Conclusion: 6:00-6:30 (30s)

**Actual Timing May Vary:**
- First run: +1-2 minutes (Docker image pulls)
- Slow network: +30s-1m
- Fast machine: -30s

---

## HTTP LoadBalancer Mode (Faster Deployment)

For demos requiring deployment, use HTTP LoadBalancer mode for faster setup:

**Config:**
```yaml
gke:
  project_id: "my-gcp-project"
  region: us-central1
  # domain_name: "example.com"  # Commented = HTTP mode
```

**Benefits:**
- Faster deployment (2-5 min vs 10-20 min)
- No DNS configuration
- No SSL certificate delays

---

## Demo Tips

**Before Demo:**
- Pre-warm Docker images: `docker pull node:20-alpine postgres:16-alpine redis:7-alpine`
- Clear terminal history
- Increase terminal font size
- Have browser ready at login page
- Test full flow once

**During Demo:**
- Speak while commands run (don't wait in silence)
- Highlight key success indicators
- Have screenshots ready as backup
- Watch timing (6-minute target)

**Key Talking Points:**
1. **One Command**: Emphasize "make dev" simplicity
2. **Zero DevOps Knowledge**: "No Kubernetes expertise needed"
3. **Production Parity**: "Same containers locally and in GKE"
4. **Time Savings**: "6 minutes vs. 4-8 hours traditional setup"

---

**Demo Status:** Ready for presentation ✅

