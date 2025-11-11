import { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import api from '../lib/api'

interface User {
  id: number
  email: string
  name: string
  createdAt: string
  updatedAt: string
}

interface AuthContextType {
  user: User | null
  token: string | null
  login: (email: string, password: string) => Promise<void>
  register: (email: string, name: string, password: string) => Promise<void>
  logout: () => void
  loading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

interface AuthProviderProps {
  children: ReactNode
}

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [user, setUser] = useState<User | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Load user and token from localStorage on mount
    const storedToken = localStorage.getItem('token')
    const storedUser = localStorage.getItem('user')

    if (storedToken && storedUser) {
      setToken(storedToken)
      setUser(JSON.parse(storedUser))
      
      // Verify token is still valid
      api.get('/auth/me')
        .then((response) => {
          if (response.data.success) {
            setUser(response.data.data.user)
            localStorage.setItem('user', JSON.stringify(response.data.data.user))
          } else {
            // Token invalid, clear storage
            localStorage.removeItem('token')
            localStorage.removeItem('user')
            setToken(null)
            setUser(null)
          }
        })
        .catch(() => {
          // Token invalid, clear storage
          localStorage.removeItem('token')
          localStorage.removeItem('user')
          setToken(null)
          setUser(null)
        })
        .finally(() => {
          setLoading(false)
        })
    } else {
      setLoading(false)
    }
  }, [])

  const login = async (email: string, password: string): Promise<void> => {
    const response = await api.post('/auth/login', { email, password })
    
    if (response.data.success) {
      const { user: userData, token: tokenData } = response.data.data
      setUser(userData)
      setToken(tokenData)
      localStorage.setItem('token', tokenData)
      localStorage.setItem('user', JSON.stringify(userData))
    } else {
      throw new Error(response.data.message || 'Login failed')
    }
  }

  const register = async (email: string, name: string, password: string): Promise<void> => {
    const response = await api.post('/auth/register', { email, name, password })
    
    if (response.data.success) {
      const { user: userData, token: tokenData } = response.data.data
      setUser(userData)
      setToken(tokenData)
      localStorage.setItem('token', tokenData)
      localStorage.setItem('user', JSON.stringify(userData))
    } else {
      throw new Error(response.data.message || 'Registration failed')
    }
  }

  const logout = () => {
    setUser(null)
    setToken(null)
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  return (
    <AuthContext.Provider value={{ user, token, login, register, logout, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

