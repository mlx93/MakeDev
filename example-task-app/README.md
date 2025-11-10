# Example Task App

A simple task management application demonstrating the Zero-to-Running Developer Environment tool.

---

## Quick Start

```bash
# 1. Clone the tool repository
git clone https://github.com/wander/zero-to-running-dev-env.git
cd zero-to-running-dev-env

# 2. Configure to use this example app
cp config.yaml.example config.yaml
# Edit config.yaml:
#   project.name: "task-app"
#   project.git_repo: "https://github.com/wander/example-task-app.git"
#   gke.project_id: "your-gcp-project-id"

# 3. Start the environment
make dev
```

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
│   │   ├── components/         # UI components
│   │   ├── pages/              # Page components
│   │   ├── context/            # React context providers
│   │   └── utils/              # Utilities (API client, etc.)
│   └── package.json
└── backend/                     # Express API
    ├── src/
    │   ├── routes/             # API routes
    │   ├── middleware/         # Express middleware
    │   └── services/           # Business logic
    ├── prisma/
    │   └── schema.prisma       # Database schema
    └── package.json
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

From the tool repository:

```bash
make dev      # Start all services locally
make seed     # Generate 30 users with 5-10 tasks each
make deploy   # Deploy to Google Kubernetes Engine
make destroy  # Teardown all resources
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

Full API documentation will be added by D&D agent.

---

## License

MIT

---

Built with ❤️ to demonstrate the Zero-to-Running Developer Environment tool.

