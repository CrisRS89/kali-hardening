import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

export function ProtectedRoute({ children, role }) {
  const { user } = useAuth()
  const location = useLocation()

  if (!user) return <Navigate to="/auth/login" state={{ from: location }} replace />
  if (role && user.role !== role) return <Navigate to="/dashboard" replace />

  return children
}
