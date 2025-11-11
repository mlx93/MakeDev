import { useState, useEffect, useRef } from 'react'
import api from '../lib/api'
import { TaskItem } from './TaskItem'
import { Task } from '../pages/DashboardPage'

interface TaskListProps {
  onEdit: (task: Task) => void
  onDelete: (id: number) => Promise<void>
  refreshTrigger: number
}

export const TaskList = ({ onEdit, onDelete, refreshTrigger }: TaskListProps) => {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [showLoadingOverlay, setShowLoadingOverlay] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const loadingTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [filters, setFilters] = useState({
    status: '' as '' | 'TODO' | 'IN_PROGRESS' | 'DONE' | 'ARCHIVED',
    priority: '' as '' | 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT',
    sort: 'createdAt' as 'title' | 'dueDate' | 'priority' | 'createdAt',
    order: 'desc' as 'asc' | 'desc'
  })

  useEffect(() => {
    const fetchTasks = async () => {
      // Clear any existing timeout
      if (loadingTimeoutRef.current) {
        clearTimeout(loadingTimeoutRef.current)
      }

      // Show loading overlay immediately for filter changes (not initial load)
      const isInitialLoad = tasks.length === 0
      if (!isInitialLoad) {
        setShowLoadingOverlay(true)
      }
      
      setLoading(true)
      setError(null)

      // Minimum loading time of 250ms to prevent flicker
      const minLoadTime = new Promise(resolve => {
        loadingTimeoutRef.current = setTimeout(resolve, 250)
      })

      try {
        const params: any = {}
        if (filters.status) params.status = filters.status
        if (filters.priority) params.priority = filters.priority
        if (filters.sort) params.sort = filters.sort
        if (filters.order) params.order = filters.order

        const [response] = await Promise.all([
          api.get('/tasks', { params }),
          minLoadTime
        ])
        
        if (response.data.success) {
          setTasks(response.data.data.tasks)
        } else {
          setError('Failed to load tasks')
        }
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to load tasks')
      } finally {
        setLoading(false)
        setShowLoadingOverlay(false)
        if (loadingTimeoutRef.current) {
          clearTimeout(loadingTimeoutRef.current)
          loadingTimeoutRef.current = null
        }
      }
    }

    fetchTasks()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, refreshTrigger])

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (loadingTimeoutRef.current) {
        clearTimeout(loadingTimeoutRef.current)
      }
    }
  }, [])

  if (loading && tasks.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-600">Loading tasks...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-4 text-sm text-red-700 bg-red-100 rounded-md">
        {error}
      </div>
    )
  }

  return (
    <div className="space-y-4 relative">
      {/* Loading Overlay */}
      {showLoadingOverlay && (
        <div className="absolute inset-0 bg-white bg-opacity-75 backdrop-blur-sm z-50 flex items-center justify-center rounded-lg">
          <div className="flex flex-col items-center space-y-3">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            <p className="text-sm font-medium text-gray-700">Loading tasks...</p>
          </div>
        </div>
      )}
      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <h3 className="text-sm font-medium text-gray-700 mb-3">Filters</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label htmlFor="status" className="block text-xs font-medium text-gray-600 mb-1">
              Status
            </label>
            <select
              id="status"
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value as any })}
              className="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All</option>
              <option value="TODO">Todo</option>
              <option value="IN_PROGRESS">In Progress</option>
              <option value="DONE">Done</option>
              <option value="ARCHIVED">Archived</option>
            </select>
          </div>
          <div>
            <label htmlFor="priority" className="block text-xs font-medium text-gray-600 mb-1">
              Priority
            </label>
            <select
              id="priority"
              value={filters.priority}
              onChange={(e) => setFilters({ ...filters, priority: e.target.value as any })}
              className="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All</option>
              <option value="LOW">Low</option>
              <option value="MEDIUM">Medium</option>
              <option value="HIGH">High</option>
              <option value="URGENT">Urgent</option>
            </select>
          </div>
          <div>
            <label htmlFor="sort" className="block text-xs font-medium text-gray-600 mb-1">
              Sort By
            </label>
            <select
              id="sort"
              value={filters.sort}
              onChange={(e) => setFilters({ ...filters, sort: e.target.value as any })}
              className="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="createdAt">Created Date</option>
              <option value="dueDate">Due Date</option>
              <option value="priority">Priority</option>
              <option value="title">Title</option>
            </select>
          </div>
          <div>
            <label htmlFor="order" className="block text-xs font-medium text-gray-600 mb-1">
              Order
            </label>
            <select
              id="order"
              value={filters.order}
              onChange={(e) => setFilters({ ...filters, order: e.target.value as any })}
              className="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="desc">Descending</option>
              <option value="asc">Ascending</option>
            </select>
          </div>
        </div>
      </div>

      {/* Task List */}
      {tasks.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow-sm border border-gray-200">
          <p className="text-gray-600">No tasks found. Create your first task!</p>
        </div>
      ) : (
        <div className="space-y-3">
          {tasks.map((task) => (
            <TaskItem
              key={task.id}
              task={task}
              onEdit={onEdit}
              onDelete={onDelete}
            />
          ))}
        </div>
      )}
    </div>
  )
}

