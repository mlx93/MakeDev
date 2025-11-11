import { Router, Request, Response } from 'express'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { PrismaClient } from '@prisma/client'
import { registerSchema, loginSchema } from '../utils/validation.js'
import { authenticate } from '../middleware/auth.js'

const router = Router()
const prisma = new PrismaClient()

// Register new user
router.post('/register', async (req: Request, res: Response): Promise<void> => {
  try {
    const validated = registerSchema.parse(req.body)
    const { email, name, password } = validated

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email }
    })

    if (existingUser) {
      res.status(409).json({
        success: false,
        error: 'CONFLICT',
        message: 'Email already registered'
      })
      return
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10)

    // Create user
    const user = await prisma.user.create({
      data: {
        email,
        name,
        password: hashedPassword
      },
      select: {
        id: true,
        email: true,
        name: true,
        createdAt: true,
        updatedAt: true
      }
    })

    // Generate JWT token
    const jwtSecret = process.env.JWT_SECRET
    if (!jwtSecret) {
      res.status(500).json({
        success: false,
        error: 'INTERNAL_ERROR',
        message: 'JWT secret not configured'
      })
      return
    }

    const token = jwt.sign(
      { userId: user.id },
      jwtSecret,
      { expiresIn: '7d' }
    )

    res.status(201).json({
      success: true,
      data: {
        user,
        token
      }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

// Login user
router.post('/login', async (req: Request, res: Response): Promise<void> => {
  try {
    const validated = loginSchema.parse(req.body)
    const { email, password } = validated

    // Find user
    const user = await prisma.user.findUnique({
      where: { email }
    })

    if (!user) {
      res.status(401).json({
        success: false,
        error: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      })
      return
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password)

    if (!isValidPassword) {
      res.status(401).json({
        success: false,
        error: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      })
      return
    }

    // Generate JWT token
    const jwtSecret = process.env.JWT_SECRET
    if (!jwtSecret) {
      res.status(500).json({
        success: false,
        error: 'INTERNAL_ERROR',
        message: 'JWT secret not configured'
      })
      return
    }

    const token = jwt.sign(
      { userId: user.id },
      jwtSecret,
      { expiresIn: '7d' }
    )

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt
        },
        token
      }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

// Get current user
router.get('/me', authenticate, async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication required'
      })
      return
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        createdAt: true,
        updatedAt: true
      }
    })

    if (!user) {
      res.status(404).json({
        success: false,
        error: 'RESOURCE_NOT_FOUND',
        message: 'User not found'
      })
      return
    }

    res.json({
      success: true,
      data: { user }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

export default router

