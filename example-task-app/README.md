# Example Task App

A simple task management application demonstrating the Zero-to-Running Developer Environment tool.

---

## Quick Start

```bash
# From the Zero-to-Running Developer Environment tool root directory:

# 1. Start the example app
make dev SUBDIR=example-task-app

# 2. Seed the database with test data
make seed SUBDIR=example-task-app

# 3. Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8080
```

The app will automatically:
- Start all services (frontend, backend, PostgreSQL, Redis)
- Run database migrations
- Enable hot reload for development

---

## Features

- **User Authentication**: Login/register with JWT tokens
- **Task Management**: Full CRUD operations for tasks
- **Responsive UI**: Modern design with Tailwind CSS
- **Real-time Updates**: Hot reload for development
- **Production-Ready**: Deploy to GKE with one command

---

## Tech Stack

**Frontend:**
- React 18.2 with TypeScript 5.3
- Vite 5.0 for blazing-fast dev server
- Tailwind CSS 3.4 for styling
- React Router 6.20 for navigation

**Backend:**
- Node.js 20 LTS with Express 4.18
- TypeScript 5.3 for type safety
- Prisma 5.7 for database access
- JWT 9.0 for authentication
- bcrypt 5.1 for password hashing

**Infrastructure:**
- PostgreSQL 16 for data storage
- Redis 7.2 for session caching
- Docker Compose for local development
- Kubernetes for production deployment

---

## Project Structure

```
example-task-app/
├── frontend/                    # React application
│   ├── src/
│   │   ├── components/         # UI components (TaskList, TaskForm, TaskItem, Layout)
│   │   ├── pages/              # Page components (Login, Register, Dashboard)
│   │   ├── contexts/           # React context providers (AuthContext)
│   │   └── lib/                # Utilities (API client)
│   ├── package.json
│   └── vite.config.ts
├── backend/                     # Express API
│   ├── src/
│   │   ├── routes/             # API routes (auth, tasks, health)
│   │   ├── middleware/         # Express middleware (auth, error handling)
│   │   └── utils/              # Utilities (validation schemas)
│   ├── prisma/
│   │   └── schema.prisma       # Database schema (User, Task models)
│   └── package.json
├── config.yaml                  # Project configuration
└── README.md                    # This file
```

---

## Environment Variables

Create `.env` in your project root:

```bash
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/appdb
REDIS_URL=redis://redis:6379
JWT_SECRET=your-secret-here
API_PORT=8080
NODE_ENV=development
VITE_API_URL=http://localhost:8080/api/v1
```

For production deployment, create `.env.production` (or the tool will use `.env`).

---

## Available Commands

From the Zero-to-Running Developer Environment tool root directory:

```bash
# Start all services locally (frontend, backend, PostgreSQL, Redis)
make dev SUBDIR=example-task-app

# Generate 30 users with 5-10 tasks each (uses seed generator)
make seed SUBDIR=example-task-app

# Deploy to Google Kubernetes Engine (when C&C Part 2 is complete)
make deploy SUBDIR=example-task-app

# Teardown all resources
make destroy SUBDIR=example-task-app
```

---

## Seeding Data

Generate realistic test data:

```bash
make seed
```

This creates:
- 30 users with realistic names and emails
- 5-10 tasks per user with varied statuses and priorities
- Proper timestamps and relationships

---

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Create new user account
- `POST /api/v1/auth/login` - Authenticate user
- `GET /api/v1/auth/me` - Get current user (requires auth)

### Tasks
- `GET /api/v1/tasks` - List user's tasks (query params: status, priority, sort, order, limit, offset)
- `GET /api/v1/tasks/:id` - Get single task
- `POST /api/v1/tasks` - Create new task
- `PATCH /api/v1/tasks/:id` - Update task
- `DELETE /api/v1/tasks/:id` - Delete task

### Health
- `GET /api/v1/health` - Basic health check
- `GET /api/v1/health/ready` - Readiness probe (checks database/Redis)

---

## License

MIT

---

Built with ❤️ to demonstrate the Zero-to-Running Developer Environment tool.

