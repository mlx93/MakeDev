# Zero-to-Running Developer Environment
## Demo Script

**Duration:** 5-8 minutes  
**Last Updated:** November 10, 2025  
**Purpose:** Live demonstration of tool capabilities

---

## Demo Scenario: New Developer Onboarding

**Duration:** 5-6 minutes  
**Setup:** Fresh laptop, new developer "Alex" joining team  
**Goal:** Show complete setup from zero to running application

### Prerequisites (Pre-demo)
- Docker Desktop running
- Terminal window ready
- Browser ready (Chrome/Firefox)
- Config file prepared (hidden from audience)

---

### Script

**[0:00-0:30] Introduction**

*"Hi, I'm going to show you how a new developer can go from zero to a running application in under 6 minutes. This is Alex's first day. They've never seen our codebase, but they need to start contributing immediately."*

---

**[0:30-1:00] Step 1: Clone Tool**

```bash
# Show command
git clone https://github.com/org/zero-to-running-dev-env
cd zero-to-running-dev-env

# Show directory structure briefly
ls
```

*"First, Alex clones our developer environment tool. This tool will handle everything."*

---

**[1:00-1:30] Step 2: Configure**

```bash
# Show config.yaml (pre-created)
cat config.yaml
```

```yaml
project:
  name: task-app
  git_repo: https://github.com/myorg/task-app

gke:
  project_id: my-gcp-project
  region: us-central1

seed:
  users: 30
  tasks_per_user: 8
```

*"Alex only needs to configure this simple YAML file—project name and repository URL. That's it. No Docker expertise needed, no complex setup scripts."*

---

**[1:30-3:30] Step 3: Start Environment (2 minutes)**

```bash
make dev
```

**Expected Output (narrate highlights):**
```
🚀 Starting local development environment...
✓ Checking Docker installation
✓ Cloning repository: https://github.com/myorg/task-app
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

*"Watch this—the tool is automatically:*
- *Cloning the application repository*
- *Building Docker containers for all services*
- *Starting PostgreSQL, Redis, backend API, and frontend*
- *Running database migrations*
- *Checking that everything is healthy*

*All with one command. No manual steps."*

---

**[3:30-4:00] Step 4: Seed Database**

```bash
make seed
```

**Expected Output:**
```
🌱 Seeding database with fake data...
✓ Generating 30 users...
✓ Generating 240 tasks (8 per user)...
✓ Seeding complete!
```

*"Now let's populate the database with realistic test data. This generates 30 users and their tasks using smart fake data generation."*

---

**[4:00-5:30] Step 6: Show Running Application**

```bash
open http://localhost:3000
```

**Demonstrate in browser:**
1. Show login page
   - *"Here's our task application, fully running"*
   
2. Login with demo credentials (pre-filled)
   - *"Authentication works with JWT tokens"*
   
3. Show task list with 240 tasks
   - *"All 240 tasks loaded from our seeded database"*
   
4. Add a new task
   - Click "Add Task" button
   - Fill in: "Demo new feature"
   - Click "Create"
   - *"Watch—task instantly appears. That's a real API call to our backend, writing to PostgreSQL"*
   
5. Mark a task as complete
   - Click checkbox on a task
   - *"Hot reload is working—I can modify code and see changes instantly without restarting"*

6. Delete a task
   - Click delete icon
   - *"Full CRUD operations working end-to-end"*

---

**[5:30-6:00] Step 7: Show Hot Reload (Optional)**

*"One more thing—let's show hot reload:"*

```bash
# In another terminal (split screen)
cd task-app/frontend/src
# Open TaskList.tsx in editor, change button text
# Save file
```

*"I just changed the 'Add Task' button text. Watch the browser—it updated automatically without refresh. This works for both frontend and backend code."*

---

**[6:00-6:30] Conclusion**

*"That's it! In 6 minutes, Alex went from nothing to a fully functional development environment with:*
- *React frontend*
- *Node.js backend API*
- *PostgreSQL database*
- *Redis cache*
- *Real authentication*
- *Hot reload for fast iteration*
- *240 realistic test records*

*And when Alex is ready to deploy? One command: `make deploy` sends everything to Google Kubernetes Engine in production-ready containers."*

---

## Alternative Demo: Empty Repository Scaffolding

**Duration:** 3-4 minutes  
**Goal:** Show project scaffolding for new applications

### Script

**[0:00-0:30] Setup**

```bash
cd zero-to-running-dev-env
cat config.yaml
```

```yaml
project:
  name: my-new-app
  git_repo: https://github.com/myorg/empty-repo  # Empty!
```

*"This time, we're starting a brand new project. The repository is completely empty."*

---

**[0:30-2:30] Generate Scaffold**

```bash
make dev
```

**Expected Output:**
```
🚀 Starting local development environment...
✓ Checking Docker installation
✓ Cloning repository: https://github.com/myorg/empty-repo
⚠️  Repository is empty. Generating project scaffold...

✓ Creating frontend/ (React + TypeScript + Tailwind)
  ├── src/components/TaskList.tsx
  ├── src/components/LoginForm.tsx
  ├── src/App.tsx
  └── ...

✓ Creating backend/ (Node.js + TypeScript + Express)
  ├── src/routes/tasks.ts
  ├── src/routes/auth.ts
  ├── prisma/schema.prisma
  └── ...

✓ Scaffold complete! Starting services...
[... continues with normal startup ...]

🎉 Environment ready!
```

*"The tool detected an empty repository and automatically generated:*
- *A complete React frontend with TypeScript and Tailwind*
- *An Express backend with TypeScript*
- *Database schema with Prisma*
- *Authentication with JWT*
- *A working example task list application*

*Everything follows best practices and is ready to customize."*

---

**[2:30-4:00] Show Generated Code**

```bash
# Show frontend structure
ls -la task-app/frontend/src/

# Show backend structure  
ls -la task-app/backend/src/

# Show Prisma schema
cat task-app/backend/prisma/schema.prisma
```

*"Look at this—complete TypeScript code, properly structured, with authentication patterns, database models, and API routes. It's not just boilerplate; it's a real working application you can learn from and extend."*

**Open browser to show running app**

*"And it's already running! We can add tasks, authenticate, everything works. Now the developer can focus on building their actual features instead of spending days on setup."*

---

## Quick GKE Deployment Demo

**Duration:** 2 minutes (summary only, don't actually wait)  
**Note:** This section is narrated, not live-executed due to 10-minute provisioning time

### Script

```bash
make deploy
```

*"When you're ready to deploy to production or staging, it's just one command: `make deploy`"*

**Show expected output (pre-recorded or slides):**
```
☁️  Deploying to Google Kubernetes Engine...
✓ Checking GCP authentication
✓ Checking for existing cluster... not found
⚙️  Provisioning GKE cluster (takes ~10 minutes)
✓ Cluster created: task-app-cluster (2 nodes, e2-medium)
✓ Building production Docker images...
✓ Pushing to Google Container Registry...
✓ Deploying PostgreSQL StatefulSet...
✓ Deploying Redis...
✓ Deploying backend (2 replicas)...
✓ Deploying frontend (3 replicas)...
✓ Waiting for LoadBalancer IP...

🎉 Deployment complete!
   Application: http://34.123.45.67
   Estimated monthly cost: $73
   
Teardown: make destroy
```

*"Behind the scenes, this command:*
1. *Uses Terraform to provision a GKE cluster*
2. *Builds production-optimized Docker images*
3. *Pushes to Google Container Registry*
4. *Deploys Kubernetes manifests*
5. *Exposes your app via a LoadBalancer*

*And when you're done testing? `make destroy` tears everything down to avoid costs."*

---

## Demo Tips & Tricks

### Before the Demo
- [ ] Pre-warm Docker by pulling base images (`node:20-alpine`, `postgres:16-alpine`, `redis:7-alpine`)
- [ ] Clear terminal history for clean demo
- [ ] Increase terminal font size for visibility
- [ ] Have browser window ready at login page
- [ ] Test full flow once to ensure timing
- [ ] Prepare fallback slides in case of network issues

### During the Demo
- **Pacing**: Speak while commands run (don't wait in silence)
- **Highlighting**: Use color output from Makefile commands
- **Backup**: Have screenshots ready if live demo fails
- **Engagement**: Ask "Who's spent a day setting up environments?" at start
- **Timing**: Watch for 6-minute mark, have clean exit if overtime

### Key Talking Points
1. **One Command**: Emphasize "make dev" simplicity repeatedly
2. **Zero DevOps Knowledge**: "No Kubernetes expertise needed"
3. **Production Parity**: "Same containers locally and in GKE"
4. **Time Savings**: "6 minutes vs. 4-8 hours traditional setup"
5. **Developer Focus**: "Write code, not infrastructure scripts"

### Common Questions & Answers

**Q: Does this work on Windows?**  
A: Yes, with WSL2. Docker Desktop on Windows with WSL2 backend works perfectly.

**Q: What about existing projects with different structures?**  
A: The config.yaml supports path overrides. We prioritize convention over configuration, but flexibility is built in.

**Q: Can we customize the generated scaffold?**  
A: Absolutely. It's just code in your repository. The scaffold is a starting point, not a constraint.

**Q: What about secrets in production?**  
A: The tool converts .env variables to Kubernetes Secrets automatically. For production, you'd use Google Secret Manager or similar.

**Q: Is this production-ready?**  
A: The deployed Kubernetes manifests follow production best practices—resource limits, health checks, StatefulSets for databases. You'd add autoscaling, monitoring, and backups for true production.

---

**Demo Status**: Ready for presentation. Practice recommended for optimal timing.
