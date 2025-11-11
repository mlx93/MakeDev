import express from 'express'
import cors from 'cors'
import healthRoutes from './routes/health.js'
import authRoutes from './routes/auth.js'
import taskRoutes from './routes/tasks.js'
import { errorHandler } from './middleware/error.js'

const app = express()

// Middleware
app.use(cors())
app.use(express.json())

// Routes
app.use('/api/v1', healthRoutes)
app.use('/api/v1/auth', authRoutes)
app.use('/api/v1/tasks', taskRoutes)

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Example Task App API',
    version: '1.0.0',
    endpoints: {
      health: '/api/v1/health',
      ready: '/api/v1/health/ready',
      auth: {
        register: 'POST /api/v1/auth/register',
        login: 'POST /api/v1/auth/login',
        me: 'GET /api/v1/auth/me'
      },
      tasks: {
        list: 'GET /api/v1/tasks',
        get: 'GET /api/v1/tasks/:id',
        create: 'POST /api/v1/tasks',
        update: 'PATCH /api/v1/tasks/:id',
        delete: 'DELETE /api/v1/tasks/:id'
      }
    }
  })
})

// Error handling middleware (must be last)
app.use(errorHandler)

export default app

