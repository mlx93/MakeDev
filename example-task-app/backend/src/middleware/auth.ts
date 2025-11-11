import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

// Extend Express Request type to include user
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: number
        email: string
        name: string
      }
    }
  }
}

export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication token required'
      })
      return
    }

    const token = authHeader.substring(7)
    const jwtSecret = process.env.JWT_SECRET

    if (!jwtSecret) {
      res.status(500).json({
        success: false,
        error: 'INTERNAL_ERROR',
        message: 'JWT secret not configured'
      })
      return
    }

    const decoded = jwt.verify(token, jwtSecret) as { userId: number }

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, email: true, name: true }
    })

    if (!user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Invalid authentication token'
      })
      return
    }

    req.user = user
    next()
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Invalid authentication token'
      })
      return
    }

    res.status(500).json({
      success: false,
      error: 'INTERNAL_ERROR',
      message: 'Authentication failed'
    })
  }
}

