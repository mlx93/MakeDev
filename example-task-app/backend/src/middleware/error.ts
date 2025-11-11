import { Request, Response, NextFunction } from 'express'
import { ZodError } from 'zod'

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Handle Zod validation errors
  if (err instanceof ZodError) {
    res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Invalid input data',
      details: err.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message
      }))
    })
    return
  }

  // Handle Prisma errors
  if (err.name === 'PrismaClientKnownRequestError') {
    // Unique constraint violation
    if ((err as any).code === 'P2002') {
      res.status(409).json({
        success: false,
        error: 'CONFLICT',
        message: 'Resource already exists'
      })
      return
    }

    // Record not found
    if ((err as any).code === 'P2025') {
      res.status(404).json({
        success: false,
        error: 'RESOURCE_NOT_FOUND',
        message: 'Resource not found'
      })
      return
    }
  }

  // Default error handler
  console.error('Error:', err)
  res.status(500).json({
    success: false,
    error: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred'
  })
}

