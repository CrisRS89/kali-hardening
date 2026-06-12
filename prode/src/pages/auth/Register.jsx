import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Trophy } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../context/ToastContext'
import { Button } from '../../components/ui/Button'

export default function Register() {
  const navigate = useNavigate()
  const { register } = useAuth()
  const { push } = useToast()
  const [form, setForm] = useState({ name: '', email: '', password: '', confirm: '' })
  const [loading, setLoading] = useState(false)

  function update(field) {
    return e => setForm(f => ({ ...f, [field]: e.target.value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    if (form.password !== form.confirm) { push('Las contraseñas no coinciden', 'error'); return }
    if (form.password.length < 6) { push('La contraseña debe tener al menos 6 caracteres', 'error'); return }
    setLoading(true)
    const { user, error } = register(form.name, form.email, form.password)
    setLoading(false)
    if (error) { push(error, 'error'); return }
    push(`¡Bienvenido al Prode, ${user.name}!`, 'success')
    navigate('/dashboard')
  }

  const fields = [
    { key: 'name',     label: 'Nombre completo', type: 'text',     placeholder: 'Juan Pérez' },
    { key: 'email',    label: 'Email',            type: 'email',    placeholder: 'tu@email.com' },
    { key: 'password', label: 'Contraseña',       type: 'password', placeholder: '••••••••' },
    { key: 'confirm',  label: 'Confirmar',        type: 'password', placeholder: '••••••••' },
  ]

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center px-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center space-y-2">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-brand-600 mb-1">
            <Trophy size={28} className="text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">Crear cuenta</h1>
          <p className="text-slate-400 text-sm">Unite al Prode y empezá a pronosticar</p>
        </div>

        <form onSubmit={handleSubmit} className="bg-slate-800 border border-slate-700 rounded-2xl p-6 space-y-4">
          {fields.map(f => (
            <div key={f.key} className="space-y-1">
              <label className="text-sm font-medium text-slate-300">{f.label}</label>
              <input
                type={f.type}
                required
                value={form[f.key]}
                onChange={update(f.key)}
                placeholder={f.placeholder}
                className="w-full bg-slate-900 border border-slate-600 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-brand-500 transition-colors"
              />
            </div>
          ))}
          <Button type="submit" className="w-full justify-center" disabled={loading}>
            {loading ? 'Creando cuenta...' : 'Crear cuenta'}
          </Button>
        </form>

        <div className="text-center space-y-2">
          <p className="text-sm text-slate-400">
            ¿Ya tenés cuenta?{' '}
            <Link to="/auth/login?role=participante" className="text-brand-400 hover:underline">Ingresá</Link>
          </p>
          <Link to="/" className="block text-xs text-slate-600 hover:text-slate-400">← Volver al inicio</Link>
        </div>
      </div>
    </div>
  )
}
