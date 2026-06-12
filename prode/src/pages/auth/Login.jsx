import { useState } from 'react'
import { useNavigate, useSearchParams, Link } from 'react-router-dom'
import { Trophy, Eye, EyeOff } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../context/ToastContext'
import { Button } from '../../components/ui/Button'

export default function Login() {
  const [params] = useSearchParams()
  const role = params.get('role') ?? 'participante'
  const isAdmin = role === 'admin'

  const navigate = useNavigate()
  const { login } = useAuth()
  const { push } = useToast()

  const [form, setForm] = useState({ email: '', password: '' })
  const [showPwd, setShowPwd] = useState(false)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)
    const { user, error } = login(form.email, form.password)
    setLoading(false)
    if (error) { push(error, 'error'); return }
    if (user.role !== role && !isAdmin) {
      push('Acceso no autorizado para este rol', 'error'); return
    }
    push(`¡Bienvenido, ${user.name}!`, 'success')
    navigate(user.role === 'admin' ? '/admin' : '/dashboard')
  }

  const demoCredentials = isAdmin
    ? { email: 'admin@prode.com', password: 'admin123' }
    : { email: 'juan@prode.com', password: '123456' }

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center px-4">
      <div className="w-full max-w-md space-y-6">

        {/* Header */}
        <div className="text-center space-y-2">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-brand-600 mb-1">
            <Trophy size={28} className="text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">
            {isAdmin ? 'Panel de Administración' : 'Ingresar al Prode'}
          </h1>
          <p className="text-slate-400 text-sm">
            {isAdmin ? 'Acceso exclusivo para administradores' : 'Ingresá tus credenciales para pronosticar'}
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-slate-800 border border-slate-700 rounded-2xl p-6 space-y-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-300">Email</label>
            <input
              type="email"
              required
              value={form.email}
              onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
              placeholder="tu@email.com"
              className="w-full bg-slate-900 border border-slate-600 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-brand-500 transition-colors"
            />
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-300">Contraseña</label>
            <div className="relative">
              <input
                type={showPwd ? 'text' : 'password'}
                required
                value={form.password}
                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                placeholder="••••••••"
                className="w-full bg-slate-900 border border-slate-600 rounded-lg px-3 py-2.5 pr-10 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-brand-500 transition-colors"
              />
              <button
                type="button"
                onClick={() => setShowPwd(s => !s)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
              >
                {showPwd ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>
          <Button type="submit" className="w-full justify-center" disabled={loading}>
            {loading ? 'Ingresando...' : 'Ingresar'}
          </Button>
        </form>

        {/* Demo hint */}
        <div className="bg-slate-800/50 border border-slate-700 rounded-lg p-3 text-xs text-slate-500 space-y-1">
          <p className="font-semibold text-slate-400">Demo {isAdmin ? 'admin' : 'participante'}:</p>
          <p>📧 {demoCredentials.email}</p>
          <p>🔑 {demoCredentials.password}</p>
        </div>

        <div className="text-center space-y-2">
          {!isAdmin && (
            <p className="text-sm text-slate-400">
              ¿No tenés cuenta?{' '}
              <Link to="/auth/register" className="text-brand-400 hover:underline">Registrate</Link>
            </p>
          )}
          <Link to="/" className="block text-xs text-slate-600 hover:text-slate-400">← Volver al inicio</Link>
        </div>
      </div>
    </div>
  )
}
