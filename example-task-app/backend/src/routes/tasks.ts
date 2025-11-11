import { Router, Request, Response } from 'express'
import { PrismaClient } from '@prisma/client'
import { createTaskSchema, updateTaskSchema, taskQuerySchema } from '../utils/validation.js'
import { authenticate } from '../middleware/auth.js'

const router = Router()
const prisma = new PrismaClient()

// Get all tasks for current user
router.get('/', authenticate, async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication required'
      })
      return
    }

    const query = taskQuerySchema.parse(req.query)
    const { status, priority, sort, order, limit, offset } = query

    const where: any = {
      userId: req.user.id
    }

    if (status) {
      where.status = status
    }

    if (priority) {
      where.priority = priority
    }

    const orderBy: any = {}
    if (sort) {
      orderBy[sort] = order || 'asc'
    } else {
      orderBy.createdAt = 'desc'
    }

    const tasks = await prisma.task.findMany({
      where,
      orderBy,
      take: limit || 100,
      skip: offset || 0,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true
          }
        }
      }
    })

    const total = await prisma.task.count({ where })

    res.json({
      success: true,
      data: {
        tasks,
        pagination: {
          total,
          limit: limit || 100,
          offset: offset || 0,
          hasMore: (offset || 0) + (limit || 100) < total
        }
      }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

// Get single task
router.get('/:id', authenticate, async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication required'
      })
      return
    }

    const taskId = parseInt(req.params.id, 10)

    if (isNaN(taskId)) {
      res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Invalid task ID'
      })
      return
    }

    const task = await prisma.task.findUnique({
      where: { id: taskId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true
          }
        }
      }
    })

    if (!task) {
      res.status(404).json({
        success: false,
        error: 'RESOURCE_NOT_FOUND',
        message: 'Task not found'
      })
      return
    }

    if (task.userId !== req.user.id) {
      res.status(403).json({
        success: false,
        error: 'FORBIDDEN',
        message: 'You do not have permission to access this task'
      })
      return
    }

    res.json({
      success: true,
      data: { task }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

// Create new task
router.post('/', authenticate, async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication required'
      })
      return
    }

    const validated = createTaskSchema.parse(req.body)
    const { title, description, priority, dueDate } = validated

    const task = await prisma.task.create({
      data: {
        title,
        description: description || null,
        priority: priority || 'MEDIUM',
        dueDate: dueDate ? new Date(dueDate) : null,
        userId: req.user.id
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true
          }
        }
      }
    })

    res.status(201).json({
      success: true,
      data: { task }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

// Update task
router.patch('/:id', authenticate, async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication required'
      })
      return
    }

    const taskId = parseInt(req.params.id, 10)

    if (isNaN(taskId)) {
      res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Invalid task ID'
      })
      return
    }

    // Check if task exists and belongs to user
    const existingTask = await prisma.task.findUnique({
      where: { id: taskId }
    })

    if (!existingTask) {
      res.status(404).json({
        success: false,
        error: 'RESOURCE_NOT_FOUND',
        message: 'Task not found'
      })
      return
    }

    if (existingTask.userId !== req.user.id) {
      res.status(403).json({
        success: false,
        error: 'FORBIDDEN',
        message: 'You do not have permission to update this task'
      })
      return
    }

    const validated = updateTaskSchema.parse(req.body)
    const updateData: any = {}

    if (validated.title !== undefined) {
      updateData.title = validated.title
    }
    if (validated.description !== undefined) {
      updateData.description = validated.description || null
    }
    if (validated.status !== undefined) {
      updateData.status = validated.status
    }
    if (validated.priority !== undefined) {
      updateData.priority = validated.priority
    }
    if (validated.dueDate !== undefined) {
      updateData.dueDate = validated.dueDate ? new Date(validated.dueDate) : null
    }

    const task = await prisma.task.update({
      where: { id: taskId },
      data: updateData,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true
          }
        }
      }
    })

    res.json({
      success: true,
      data: { task }
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

// Delete task
router.delete('/:id', authenticate, async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message: 'Authentication required'
      })
      return
    }

    const taskId = parseInt(req.params.id, 10)

    if (isNaN(taskId)) {
      res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Invalid task ID'
      })
      return
    }

    // Check if task exists and belongs to user
    const existingTask = await prisma.task.findUnique({
      where: { id: taskId }
    })

    if (!existingTask) {
      res.status(404).json({
        success: false,
        error: 'RESOURCE_NOT_FOUND',
        message: 'Task not found'
      })
      return
    }

    if (existingTask.userId !== req.user.id) {
      res.status(403).json({
        success: false,
        error: 'FORBIDDEN',
        message: 'You do not have permission to delete this task'
      })
      return
    }

    await prisma.task.delete({
      where: { id: taskId }
    })

    res.json({
      success: true,
      message: 'Task deleted'
    })
  } catch (error) {
    // Error handling middleware will catch this
    throw error
  }
})

export default router

