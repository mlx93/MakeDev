import { useState } from 'react'
import { Layout } from '../components/Layout'
import { TaskList } from '../components/TaskList'
import { TaskForm } from '../components/TaskForm'
import api from '../lib/api'

export interface Task {
  id: number
  title: string
  description: string | null
  status: 'TODO' | 'IN_PROGRESS' | 'DONE' | 'ARCHIVED'
  priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
  dueDate: string | null
  userId: number
  createdAt: string
  updatedAt: string
}

export const DashboardPage = () => {
  const [showForm, setShowForm] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [refreshTrigger, setRefreshTrigger] = useState(0)

  const handleCreateTask = async (data: {
    title: string
    description: string
    priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
    dueDate: string
  }) => {
    await api.post('/tasks', data)
    setShowForm(false)
    setRefreshTrigger(prev => prev + 1)
  }

  const handleUpdateTask = async (data: {
    title: string
    description: string
    priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT'
    dueDate: string
  }) => {
    if (!editingTask) return

    await api.patch(`/tasks/${editingTask.id}`, {
      ...data,
      status: editingTask.status // Preserve status unless explicitly changed
    })
    setEditingTask(null)
    setRefreshTrigger(prev => prev + 1)
  }

  const handleEditTask = (task: Task) => {
    setEditingTask(task)
    setShowForm(true)
  }

  const handleDeleteTask = async (id: number) => {
    if (!confirm('Are you sure you want to delete this task?')) return

    try {
      await api.delete(`/tasks/${id}`)
      setRefreshTrigger(prev => prev + 1)
    } catch (error) {
      alert('Failed to delete task')
    }
  }

  const handleCancelForm = () => {
    setShowForm(false)
    setEditingTask(null)
  }

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold text-gray-900">My Tasks</h2>
          {!showForm && (
            <button
              onClick={() => setShowForm(true)}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Create Task
            </button>
          )}
        </div>

        {showForm && (
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              {editingTask ? 'Edit Task' : 'Create New Task'}
            </h3>
            <TaskForm
              onSubmit={editingTask ? handleUpdateTask : handleCreateTask}
              onCancel={handleCancelForm}
              initialData={editingTask ? {
                title: editingTask.title,
                description: editingTask.description || '',
                priority: editingTask.priority,
                dueDate: editingTask.dueDate ? new Date(editingTask.dueDate).toISOString().slice(0, 16) : ''
              } : undefined}
              submitLabel={editingTask ? 'Update Task' : 'Create Task'}
            />
          </div>
        )}

        <TaskList
          onEdit={handleEditTask}
          onDelete={handleDeleteTask}
          refreshTrigger={refreshTrigger}
        />
      </div>
    </Layout>
  )
}

