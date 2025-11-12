# Video Demo Script Final

**Duration:** 5-7 minutes  
**Target:** Quick, focused demonstration of core workflow

---

## Setup

**Prerequisites:**
- Docker Desktop running
- GCP project configured
- GitHub CLI authenticated
- Terminal ready, browser ready

**Voice-Over:**
*"I'm going to show you how to go from zero to a running application deployed on Google Kubernetes Engine in under 10 minutes. We'll start with absolutely nothing—no code, no project—just the MakeDev tool."*

---

## Part 1: Hello World App (2-3 minutes)

### Step 1: Clone MakeDev Repo

**Command:**
```bash
git clone https://github.com/mlx93/MakeDev.git MakeDev
cd MakeDev
```

**Voice-Over:**
*"Let's start by cloning the MakeDev repository. This is the tool that will help us go from zero to a running application in minutes."*

---

### Step 2: Create and Run Hello World App Locally

**Command:**
```bash
make dev SUBDIR=example-hello-app
```

**Voice-Over (during scaffolding - 1:30-2:00):**
*"Watch this—MakeDev is automatically creating our project structure. It's generating a React frontend, a Node.js backend with Express, setting up TypeScript, Tailwind CSS, and Prisma for database access. All of this happens automatically—no manual setup required."*

**Voice-Over (during Docker build - 2:00-2:30):**
*"Now MakeDev is building Docker containers for local development. It's creating development images with hot reload enabled—the backend uses TypeScript with live reload, and the frontend uses Vite's dev server. These are development-optimized images designed for fast iteration. When we deploy to production later, MakeDev will build production-optimized images instead."*

**Voice-Over (during services starting - 2:30-3:00):**
*"The services are starting up now. PostgreSQL database is initializing, Redis cache is starting, and our backend API is coming online. Notice how MakeDev handles all the service dependencies automatically—the database starts before the backend, and the backend starts before the frontend."*

**Voice-Over (during health checks - 3:00-3:30):**
*"Health checks are passing. All services are healthy and ready. Our frontend is accessible at localhost:3000, and the backend API is running on localhost:8080. Let me show you it's actually working."*

**Action:**
- Wait for services to be healthy
- Open browser to `http://localhost:3000`
- Show hello world app running

**Voice-Over:**
*"There it is—our hello world application running locally. Frontend, backend, database, and cache all running with zero manual configuration."*

---

### Step 3: Deploy Hello World App to Production

**Command:**
```bash
make deploy SUBDIR=example-hello-app
```

**Voice-Over:**
*"Now comes the exciting part—deploying to production. With MakeDev, this is just one command: `make deploy`. Since our config.yaml was created with minimal settings for local development, MakeDev will automatically detect that GCP settings are missing and prompt us interactively for our GCP project ID. After entering it, we can accept all default settings with a single 'Y', and this single command will provision a GKE cluster, build production Docker images, push them to Google Artifact Registry, deploy to Kubernetes, and configure everything we need for production."*

**Voice-Over (during config prompt):**
*"MakeDev detected that our config file is missing GCP settings, so it's prompting us interactively. I'll enter my GCP project ID and accept all default settings."*

**Action:**
- Enter GCP project ID when prompted
- Press Enter to accept all defaults
- Show the summary table of applied settings

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

**Action:**
- Wait for deployment to complete
- Open browser to production URL
- Show hello world app running in production

**Voice-Over:**
*"Deployment complete! Our application is now running in production on Google Kubernetes Engine, accessible from anywhere on the internet. We went from zero to production in about 3 minutes."*

---

## Part 2: Task App (2-3 minutes)

### Step 4: Clone Task App Repository

**Command:**
```bash
cd MakeDev
git clone https://github.com/mlx93/task-app.git task-app
```

**Voice-Over:**
*"Now let's demonstrate with a real application—the example task app. This is a full-featured task management application with authentication and CRUD operations."*

---

### Step 5: Run Task App Locally

**Command:**
```bash
make dev SUBDIR=task-app
```

**Voice-Over (during startup):**
*"MakeDev detected this is an existing repository, so it's using the existing code. It's still setting up Docker containers, starting services, and running database migrations automatically."*

**Command:**
```bash
make seed SUBDIR=task-app
```

**Commentary Point 13.5 - Seeding Database (9:00-9:15):**
*"Now let's seed the database with realistic test data. MakeDev reads the Prisma schema and generates 30 users with 5 to 10 tasks each, using Faker.js for realistic names, emails, and task descriptions. This gives us data to work with immediately."*

**Action:**
- Open browser to `http://localhost:3000`
- Login with `demo@example.com` / `demo123`
- Show task list with seeded tasks
- Demonstrate adding a task

**Voice-Over:**
*"There's our task application running locally with seeded data. Full authentication, task management, everything working."*

---

### Step 6: Deploy Task App to Production

**Command:**
```bash
make deploy SUBDIR=task-app
```

**Voice-Over (during config prompt):**
*"Now let's deploy the task app. Since this project doesn't have a config.yaml file yet, MakeDev will prompt us for GCP settings. I'll enter my project ID and accept defaults again."*

**Voice-Over (during deployment):**
*"MakeDev is automatically committing and pushing our code to GitHub, reusing our existing GKE cluster to save time and money, building production-optimized Docker images, and deploying to Kubernetes. Watch as it creates a namespace for our task app, deploys all services—frontend, backend, PostgreSQL database, Redis cache—with high availability, seeds the database with realistic test data automatically, and sets up a LoadBalancer for public access. All happening automatically."*

**Action:**
- Wait for deployment to complete
- Open browser to production URL
- Login and show tasks

**Voice-Over:**
*"Deployment complete! Our task application is now running in production. We've demonstrated MakeDev with both a scaffolded hello world app and an existing real-world application. From zero to production in minutes, with minimal configuration."*

---

## Conclusion

**Voice-Over:**
*"So what did we accomplish? We went from zero to a production-deployed hello world application in about 7 minutes. Then we deployed a full-featured task management application to production in about 5 minutes. All with single commands—no manual Docker configuration, no Kubernetes expertise required, no complex setup scripts. MakeDev handles everything: scaffolding, Docker, Kubernetes, database migrations, seeding, GitHub integration, and production deployment. This is what developer productivity looks like."*

---

## Key Talking Points

- **Simplicity**: "One command does everything"
- **Automation**: "No manual steps required"
- **Speed**: "From zero to production in minutes"
- **Flexibility**: "Works with new projects and existing projects"
- **Production-Ready**: "Real Kubernetes deployment, not a demo"

---

## Execution Checklist

- [ ] Docker Desktop running
- [ ] GCP project configured
- [ ] GitHub CLI authenticated
- [ ] Clone MakeDev repo
- [ ] `make dev SUBDIR=example-hello-app`
- [ ] Show hello world app (localhost:3000)
- [ ] `make deploy SUBDIR=example-hello-app` (enter GCP project ID, accept defaults)
- [ ] Show hello world app (production URL)
- [ ] Clone task-app repo
- [ ] `make dev SUBDIR=task-app`
- [ ] `make seed SUBDIR=task-app`
- [ ] Show task app (localhost:3000) with seeded data
- [ ] `make deploy SUBDIR=task-app` (enter GCP project ID, accept defaults)
- [ ] Show task app (production URL)

---

**Total Duration:** 5-7 minutes  
**Key Commands:** 6 commands total  
**Complexity:** Simple—demonstrates core workflow

