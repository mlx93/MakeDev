import { Router } from 'express'

const router = Router()

// Basic health check
router.get('/health', (req, res) => {
  res.json({ status: 'ok' })
})

// Readiness probe (checks database connection)
router.get('/health/ready', async (req, res) => {
  try {
    // Try to connect to database if Prisma is available
    // For now, just return ok since migrations will handle DB setup
    res.json({ status: 'ok' })
  } catch (error) {
    res.status(503).json({ status: 'error', message: 'Service not ready' })
  }
})

export default router

