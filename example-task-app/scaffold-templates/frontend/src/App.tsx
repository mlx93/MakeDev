import { useState, useEffect } from 'react'

function App() {
  const [backendStatus, setBackendStatus] = useState<string>('checking...')

  useEffect(() => {
    // Check backend health
    fetch('/api/health')
      .then(res => res.json())
      .then(data => {
        setBackendStatus(data.status === 'ok' ? '✅ Connected' : '❌ Error')
      })
      .catch(() => {
        setBackendStatus('❌ Not connected')
      })
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl p-8 max-w-2xl w-full">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          🚀 Hello World!
        </h1>
        <p className="text-lg text-gray-600 mb-6">
          Welcome to <span className="font-semibold">{{PROJECT_NAME}}</span>
        </p>
        <div className="space-y-4">
          <div className="p-4 bg-green-50 rounded-lg border border-green-200">
            <p className="text-sm text-gray-700 mb-2">
              <strong>Frontend:</strong> React + Vite + TypeScript + Tailwind CSS
            </p>
            <p className="text-sm text-green-700">✅ Running on http://localhost:3000</p>
          </div>
          <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
            <p className="text-sm text-gray-700 mb-2">
              <strong>Backend:</strong> {backendStatus}
            </p>
            <p className="text-sm text-blue-700">Running on http://localhost:8080</p>
          </div>
        </div>
        <div className="mt-8 pt-6 border-t border-gray-200">
          <p className="text-sm text-gray-500">
            ✨ Your development environment is ready! Start building your app.
          </p>
        </div>
      </div>
    </div>
  )
}

export default App

