# Video Demo Script: Zero-to-Running Developer Environment
## Complete Workflow Demonstration

**Duration:** 10-12 minutes  
**Last Updated:** November 11, 2025  
**Purpose:** Video demonstration showing hello world app creation and task app deployment

---

## Prerequisites (Pre-Recording Setup)

- [ ] Fresh terminal window ready
- [ ] Browser ready (Chrome/Firefox)
- [ ] Docker Desktop running
- [ ] GCP project configured (project_id ready)
- [ ] GitHub CLI authenticated (`gh auth login` if needed)
- [ ] Clean workspace (no existing projects)

---

## Part 1: Hello World App from Scratch (6-8 minutes)

### [0:00-0:30] Introduction

**Voice-Over:**
*"I'm going to show you how to go from zero to a running application deployed on Google Kubernetes Engine in under 10 minutes. We'll start with absolutely nothing—no code, no project—just the MakeDev tool."*

**Action:**
- Show empty terminal
- Show empty workspace

---

### [0:30-1:00] Clone MakeDev Repository

**Voice-Over:**
*"First, let's clone the MakeDev repository. This is the only thing we need to get started."*

**Command:**
```bash
git clone https://github.com/mlx93/MakeDev.git
cd MakeDev
```

**Expected Output:**
```
Cloning into 'MakeDev'...
remote: Enumerating objects: X, done.
remote: Counting objects: 100% (X/X), done.
remote: Compressing objects: 100% (X/X), done.
Receiving objects: 100% (X/X), done.
```

**Voice-Over:**
*"Perfect. Now we have the MakeDev tool. Notice we don't have any application code yet—we're starting completely from scratch."*

---

### [1:00-1:30] Create Hello World App Locally

**Voice-Over:**
*"Now for the magic—let's create our hello world application from scratch. I'll run `make dev` on a folder that doesn't exist yet, and MakeDev will automatically scaffold a complete React and Node.js application for us. It creates a minimal config.yaml file with just the project name—we don't need any GCP configuration for local development."*

**Command:**
```bash
make dev SUBDIR=hello-world-app
```

**Expected Output (Initial Setup):**
```
🔧 Creating new project in subdirectory: hello-world-app
   Creating Makefile (include ../Makefile)
   Bootstrapping tool infrastructure...
   Setting git_repo to empty (greenfield scaffold)
```

**Voice-Over:**
*"MakeDev is automatically creating the project structure and a minimal config.yaml file. Notice it's setting git_repo to empty, which tells MakeDev this is a greenfield project that should be scaffolded from scratch. The config.yaml only has what we need for local development—no GCP settings required yet."*

---

**Expected Output (Key Moments for Commentary):**

**Commentary Point 1 - Scaffolding (1:30-2:00):**
*"Watch this—MakeDev is automatically creating our project structure. It's generating a React frontend with Vite, a Node.js backend with Express, setting up TypeScript, Tailwind CSS, and Prisma for database access. All of this happens automatically—no manual setup required."*

**Commentary Point 2 - Docker Build (2:00-2:30):**
*"Now MakeDev is building Docker containers for our application. It's creating optimized images for both the frontend and backend services. This ensures our application will run consistently whether it's on my machine or in production."*

**Commentary Point 3 - Services Starting (2:30-3:00):**
*"The services are starting up now. PostgreSQL database is initializing, Redis cache is starting, and our backend API is coming online. Notice how MakeDev handles all the service dependencies automatically—the database starts before the backend, and the backend starts before the frontend."*

**Commentary Point 4 - Health Checks (3:00-3:30):**
*"Health checks are passing. All services are healthy and ready. Our frontend is accessible at localhost:3000, and the backend API is running on localhost:8080. Let me show you it's actually working."*

**Action:**
- Open browser to `http://localhost:3000`
- Show hello world app running
- Show it's a real React app (inspect if needed)

**Voice-Over:**
*"There it is—our hello world application, fully functional, running locally. We went from nothing to a working application in about 2 minutes."*

---

### [3:30-4:00] Verify Local Setup

**Voice-Over:**
*"Let me quickly verify everything is working correctly. I'll check the health endpoints to confirm all services are operational."*

**Command:**
```bash
curl http://localhost:8080/api/v1/health
```

**Expected Output:**
```json
{"status":"ok"}
```

**Voice-Over:**
*"Perfect. All services are healthy. Now let's deploy this to production on Google Kubernetes Engine."*

---

### [4:00-8:00] Deploy Hello World App to GKE

**Voice-Over:**
*"Now comes the exciting part—deploying to production. With MakeDev, this is just one command: `make deploy`. Since our config.yaml doesn't have GCP settings yet, MakeDev will detect that and prompt us interactively for our GCP project ID. After entering it, this single command will provision a GKE cluster, build production Docker images, push them to Google Artifact Registry, deploy to Kubernetes, and configure everything we need for production."*

**Note for Demo:** Currently, if config.yaml exists with placeholder project_id, `make deploy` will error. For smooth demo flow:
- Option 1 (Recommended): Delete `hello-world-app/config.yaml` before running `make deploy` to trigger interactive prompt
- Option 2: Manually edit `hello-world-app/config.yaml` to set `project_id: "your-actual-project-id"` before running `make deploy`

**Command:**
```bash
make deploy SUBDIR=hello-world-app
```

**Expected Output (Interactive Config Prompt - if config.yaml is missing or GCP settings incomplete):**
```
⚠️  config.yaml not found in hello-world-app
Let's create one! (takes ~1 minute)

⚙️  Zero-to-Running Config Generator
==========================================

📦 Project Configuration
──────────────────────────────────────────

Enter your project name (e.g., my-app, task-tracker): hello-world-app

🔗 GitHub Configuration
──────────────────────────────────────────

We'll create a GitHub repository for you during deployment.
Enter desired GitHub repo name (default: hello-world-app): [press Enter]

☁️  Google Cloud Platform (GKE) Configuration
──────────────────────────────────────────

To find your GCP project ID:
  1. Visit: https://console.cloud.google.com/
  2. Select your project from the dropdown
  3. Copy the Project ID (not the name)

Enter your GCP project ID: [enter your GCP project ID]
```

**Voice-Over:**
*"MakeDev detected that we need GCP configuration for deployment, so it's prompting us interactively. I'll enter my GCP project ID, and it will create a complete config.yaml file with all the settings we need."*

**Expected Output (Key Moments for Commentary - After Config):**

**Commentary Point 5 - Configuration Complete (4:00-4:15):**
*"Configuration is complete. MakeDev has created our config.yaml file with all the settings we need. Now it's ready to deploy."*

**Commentary Point 6 - GitHub Setup (4:15-4:45):**
*"First, MakeDev is setting up our GitHub repository. It's automatically creating the repo, connecting it to our local code, and pushing our code to GitHub. All of this happens automatically—no manual git commands needed."*

**Commentary Point 7 - Terraform Cluster Provisioning (4:45-5:45):**
*"Now MakeDev is provisioning our Google Kubernetes Engine cluster using Terraform. This is infrastructure as code—the cluster is being created with all the right settings: the right machine types, the right node count, the right region. This typically takes about 5-7 minutes, but it only happens once. If the cluster already exists, MakeDev will reuse it."*

**Commentary Point 8 - Docker Image Build (5:45-6:15):**
*"While the cluster is provisioning, MakeDev is building production Docker images. These are optimized images—smaller, faster, production-ready. The images are being pushed to Google Artifact Registry, which is Google's container registry."*

**Commentary Point 9 - Kubernetes Deployment (6:15-6:45):**
*"Now the deployment is happening. MakeDev is applying Kubernetes manifests—creating deployments for our frontend and backend, setting up services, configuring networking. All of this is happening automatically."*

**Commentary Point 10 - Pods Forming (6:45-7:15):**
*"Watch the pods come online. Kubernetes is scheduling our containers onto nodes, pulling the Docker images, and starting our services. You can see the pods transitioning from 'Pending' to 'Running' status. This is Kubernetes orchestrating our application."*

**Commentary Point 11 - Database Seeding (7:15-7:30):**
*"The database is being seeded automatically. MakeDev detected our Prisma schema and is generating realistic test data. This happens automatically during deployment—no manual steps needed."*

**Commentary Point 12 - LoadBalancer IP Assignment (7:30-7:45):**
*"The LoadBalancer is assigning a public IP address. This is what will make our application accessible from the internet. The IP assignment typically takes 2-3 minutes."*

**Expected Final Output:**
```
✅ Deployment complete!

🌐 Frontend URL: http://XXX.XXX.XXX.XXX
💰 Estimated monthly cost: ~$68-73/month
```

**Voice-Over:**
*"Deployment complete! Our hello world application is now running in production on Google Kubernetes Engine. Let me open it in the browser to show you it's actually working."*

**Action:**
- Open browser to the LoadBalancer IP
- Show hello world app running in production
- Show it's the same app, now in production

**Voice-Over:**
*"There it is—our hello world application, deployed to production, accessible from anywhere on the internet. We went from zero to production in about 8 minutes, and the only thing we had to configure was our GCP project ID when prompted."*

---

## Part 2: Task App Deployment (5-6 minutes)

### [7:30-8:00] Clone Task App Repository

**Voice-Over:**
*"Now let's demonstrate with a real application—the example task app. This is a full-featured task management application with authentication, CRUD operations, and a complete frontend. I'll clone it into a new folder within MakeDev."*

**Command:**
```bash
cd MakeDev
git clone https://github.com/yourusername/example-task-app.git task-app
cd task-app
```

**Voice-Over:**
*"Perfect. Now we have the task app code locally. Notice it's a complete application with a Prisma schema, backend API routes, and a React frontend."*

---

### [8:00-9:00] Run Task App Locally

**Voice-Over:**
*"Let's run this locally first to show it works. I'll use MakeDev's `make dev` command, but this time pointing to an existing repository instead of scaffolding a new one."*

**Command:**
```bash
cd ..
make dev SUBDIR=task-app
```

**Expected Output:**
- Services starting
- Database migrations running
- Health checks passing

**Commentary Point 12 - Existing Repo Detection (8:00-8:30):**
*"MakeDev detected this is an existing repository, so it's not scaffolding—it's using the existing code. It's still setting up Docker containers, starting services, and running database migrations automatically."*

**Commentary Point 13 - Migrations Running (8:30-9:00):**
*"Prisma migrations are running automatically. MakeDev detected the Prisma schema and is applying all migrations. The database is being set up with the correct schema—User and Task tables, relationships, indexes—all automatically."*

**Command:**
```bash
make seed SUBDIR=task-app
```

**Commentary Point 13.5 - Seeding Database (9:00-9:15):**
*"Now let's seed the database with realistic test data. MakeDev reads the Prisma schema and generates 30 users with 5 to 10 tasks each, using Faker.js for realistic names, emails, and task descriptions. This gives us data to work with immediately."*

**Action:**
- Open browser to `http://localhost:3000`
- Show task app login page
- Login with demo credentials: `demo@example.com` / `demo123`
- Show task list with seeded tasks
- Demonstrate CRUD (add a task, mark complete, delete)

**Voice-Over:**
*"There's our task application, running locally with seeded data. Full authentication, task management, everything working. Now let's deploy this to production."*

---

### [9:30-12:30] Deploy Task App to GKE

**Voice-Over:**
*"Now let's deploy the task app to production. This time, MakeDev will push our code to the task app's GitHub repository and deploy it to GKE. Watch how it handles everything automatically."*

**Command:**
```bash
make deploy SUBDIR=task-app
```

**Expected Output (Key Moments for Commentary):**

**Commentary Point 14 - Git Push to Task App Repo (9:30-10:00):**
*"MakeDev is automatically committing our local changes and pushing them to the task app's GitHub repository. Notice how it's updating the remote repository—this ensures our production deployment uses the latest code."*

**Commentary Point 15 - Cluster Reuse (10:00-10:30):**
*"MakeDev detected we already have a GKE cluster, so it's reusing it instead of creating a new one. This saves time and money—we're not provisioning duplicate infrastructure."*

**Commentary Point 16 - Production Image Build (10:30-11:00):**
*"Production Docker images are being built. These are optimized for production—smaller images, faster startup times, better security. The images include only what's needed to run the application."*

**Commentary Point 17 - Kubernetes Namespace (11:00-11:30):**
*"Kubernetes is creating a namespace for our task app. Notice the namespace is based on the project name—this ensures multiple projects can run in the same cluster without conflicts."*

**Commentary Point 18 - Services Deploying (11:30-12:00):**
*"All services are deploying: frontend, backend, PostgreSQL database, Redis cache. Kubernetes is managing the deployment, ensuring high availability with multiple replicas, handling rolling updates, and managing service discovery."*

**Commentary Point 19 - Database Seeding in Production (12:00-12:30):**
*"The database is being seeded with demo data. MakeDev read our Prisma schema, detected the User and Task models, and is generating realistic test data—30 users with 8 tasks each. This all happens automatically during deployment."*

**Expected Final Output:**
```
✅ Deployment complete!

🌐 Frontend URL: http://XXX.XXX.XXX.XXX
💰 Estimated monthly cost: ~$68-73/month

Demo credentials:
  Email: demo@example.com
  Password: demo123
```

**Voice-Over:**
*"Deployment complete! Our task application is now running in production. Let me show you it's working."*

**Action:**
- Open browser to the LoadBalancer IP
- Show task app login page
- Login with demo credentials
- Show task list with seeded data
- Demonstrate it's fully functional

**Voice-Over:**
*"Perfect! Our task application is running in production, with all features working: authentication, task management, database persistence. We deployed a complete, production-ready application with a single command."*

---

## [12:00-12:30] Conclusion

**Voice-Over:**
*"So what did we accomplish? We went from zero to a production-deployed hello world application in about 7 minutes. Then we deployed a full-featured task management application to production in about 5 minutes. All with single commands—no manual Docker configuration, no Kubernetes expertise required, no complex setup scripts. MakeDev handles everything: scaffolding, Docker, Kubernetes, database migrations, seeding, GitHub integration, and production deployment. This is what developer productivity looks like."*

**Action:**
- Show both applications running (hello world and task app)
- Show terminal with simple commands used
- End with MakeDev logo or summary slide

---

## Execution Checklist

### Pre-Recording
- [ ] Docker Desktop running
- [ ] GCP project configured
- [ ] GitHub CLI authenticated
- [ ] Clean workspace
- [ ] Browser ready
- [ ] Terminal ready

### Recording Part 1 (Hello World)
- [ ] Clone MakeDev repo
- [ ] Run `make dev SUBDIR=hello-world-app` (auto-creates minimal config.yaml with project name only, no GCP settings)
- [ ] Show app in browser (localhost:3000)
- [ ] Delete `hello-world-app/config.yaml` (to trigger interactive prompt during deploy) OR edit it to add GCP project_id
- [ ] Run `make deploy SUBDIR=hello-world-app` (will prompt for GCP project ID interactively)
- [ ] Show app in browser (production URL)

### Recording Part 2 (Task App)
- [ ] Clone task app repo into MakeDev folder
- [ ] Run `make dev SUBDIR=task-app`
- [ ] Run `make seed SUBDIR=task-app` (to populate database with test data)
- [ ] Show app in browser (localhost:3000)
- [ ] Login and demonstrate features (show seeded tasks)
- [ ] Run `make deploy SUBDIR=task-app`
- [ ] Show app in browser (production URL)
- [ ] Login and demonstrate features

### Post-Recording
- [ ] Review footage for clarity
- [ ] Note: GKE resources can be cleaned up manually via GCP Console if needed

---

## Tips for Recording

1. **Terminal Size**: Use a large terminal window (full screen or split screen)
2. **Font Size**: Use readable font size (14-16pt)
3. **Speed**: Let commands run at normal speed—don't rush
4. **Pauses**: Pause during long operations (cluster provisioning) to add commentary
5. **Browser**: Have browser ready to switch to quickly
6. **Commentary**: Speak clearly during terminal output—explain what's happening
7. **Errors**: If something fails, show the error and explain how to fix it (or edit out)

---

## Key Talking Points

- **Simplicity**: "One command does everything"
- **Automation**: "No manual steps required"
- **Speed**: "From zero to production in minutes"
- **Production-Ready**: "Real Kubernetes deployment, not a demo"
- **Developer Experience**: "Focus on code, not infrastructure"
- **Flexibility**: "Works with new projects and existing projects"

---

**Total Duration:** ~13-14 minutes  
**Key Commands:** 4 commands total (`make dev`, `make seed`, `make deploy` × 2)  
**Complexity:** Simple—demonstrates ease of use (no separate config step needed)

**Note:** `make destroy` has been removed from this demo script due to safety concerns. The command is currently disabled in the codebase.

