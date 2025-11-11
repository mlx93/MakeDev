import { Router, Request, Response } from 'express'
import { PrismaClient } from '@prisma/client'
import Redis from 'ioredis'

const router = Router()
const prisma = new PrismaClient()

// Initialize Redis client if REDIS_URL is available
let redis: Redis | null = null
if (process.env.REDIS_URL) {
  try {
    redis = new Redis(process.env.REDIS_URL)
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn('Redis client initialization failed:', error)
  }
}

// Basic health check
router.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok' })
})

// Readiness probe (checks database and Redis connections)
router.get('/health/ready', async (_req: Request, res: Response) => {
  const errors: string[] = []

  try {
    // Check PostgreSQL connection via Prisma
    await prisma.$queryRaw`SELECT 1`
  } catch (error) {
    errors.push('Database connection failed')
  }

  // Check Redis connection if enabled
  if (redis) {
    try {
      await redis.ping()
    } catch (error) {
      errors.push('Redis connection failed')
    }
  }

  if (errors.length > 0) {
    return res.status(503).json({
      status: 'error',
      message: 'Service not ready',
      errors
    })
  }

  res.json({ status: 'ok' })
})

export default router

