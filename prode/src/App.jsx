import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { ThemeProvider } from './context/ThemeContext'
import { AuthProvider } from './context/AuthContext'
import { ToastProvider } from './context/ToastContext'
import { ProtectedRoute } from './components/layout/ProtectedRoute'

import Welcome        from './pages/Welcome'
import Login          from './pages/auth/Login'
import Register       from './pages/auth/Register'
import Dashboard      from './pages/participant/Dashboard'
import Predictions    from './pages/participant/Predictions'
import Ranking        from './pages/participant/Ranking'
import AdminDashboard from './pages/admin/AdminDashboard'
import ImportMatches  from './pages/admin/ImportMatches'

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <ToastProvider>
          <BrowserRouter>
            <Routes>
              <Route path="/"              element={<Welcome />} />
              <Route path="/auth/login"    element={<Login />} />
              <Route path="/auth/register" element={<Register />} />

              <Route path="/dashboard" element={
                <ProtectedRoute role="participante"><Dashboard /></ProtectedRoute>
              } />
              <Route path="/dashboard/pronosticos" element={
                <ProtectedRoute role="participante"><Predictions /></ProtectedRoute>
              } />
              <Route path="/dashboard/ranking" element={
                <ProtectedRoute role="participante"><Ranking /></ProtectedRoute>
              } />

              <Route path="/admin" element={
                <ProtectedRoute role="admin"><AdminDashboard /></ProtectedRoute>
              } />
              <Route path="/admin/importar" element={
                <ProtectedRoute role="admin"><ImportMatches /></ProtectedRoute>
              } />

              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
        </ToastProvider>
      </AuthProvider>
    </ThemeProvider>
  )
}
