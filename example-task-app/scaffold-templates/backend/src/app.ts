import express from 'express'
import cors from 'cors'
import healthRoutes from './routes/health.js'

const app = express()

// Middleware
app.use(cors())
app.use(express.json())

// Routes
app.use('/api/v1', healthRoutes)

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Hello World API',
    version: '1.0.0',
    endpoints: {
      health: '/api/v1/health',
      ready: '/api/v1/health/ready'
    }
  })
})

export default app

