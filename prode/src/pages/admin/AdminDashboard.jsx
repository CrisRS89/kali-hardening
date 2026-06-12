import { useNavigate } from 'react-router-dom'
import { LogOut, Settings, Download, CheckSquare, BarChart2, Sun, Moon } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { useTheme } from '../../context/ThemeContext'
import { Card } from '../../components/ui/Card'
import { mockTournaments } from '../../data/mockData'

const ACTIONS = [
  { label: 'Gestionar torneo',     icon: Settings,     path: '/admin/torneo',     color: 'text-brand-400', desc: 'Crear fechas y partidos' },
  { label: 'Importar partidos',    icon: Download,     path: '/admin/importar',   color: 'text-emerald-400', desc: 'Un click por liga' },
  { label: 'Registrar resultados', icon: CheckSquare,  path: '/admin/resultados', color: 'text-amber-400', desc: 'Cargar marcadores oficiales' },
  { label: 'Calcular puntajes',    icon: BarChart2,    path: '/admin/puntajes',   color: 'text-purple-400', desc: 'Motor de puntos + XP' },
]

export default function AdminDashboard() {
  const { user, logout } = useAuth()
  const { dark, toggle } = useTheme()
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col">
      <header className="bg-slate-800 border-b border-slate-700 px-4 py-3 flex items-center justify-between">
        <div>
          <p className="font-bold text-white text-sm">⚙️ Panel Admin</p>
          <p className="text-xs text-slate-500">{user?.name}</p>
        </div>
        <div className="flex gap-2">
          <button onClick={toggle} className="p-1.5 rounded-lg hover:bg-slate-700 text-slate-400 hover:text-white">
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <button onClick={() => { logout(); navigate('/') }} className="p-1.5 rounded-lg hover:bg-slate-700 text-slate-400 hover:text-red-400">
            <LogOut size={18} />
          </button>
        </div>
      </header>

      <main className="max-w-lg mx-auto w-full px-4 py-6 space-y-4">

        {/* Active tournaments */}
        <Card>
          <h2 className="font-semibold text-white text-sm mb-3">Torneos activos</h2>
          {mockTournaments.map(t => (
            <div key={t.id} className="flex items-center justify-between py-2 border-b border-slate-700 last:border-0">
              <div>
                <p className="text-sm text-white font-medium">{t.name}</p>
                <p className="text-xs text-slate-500">{t.participants} participantes · {t.predictionMode === 'LEV' ? 'L·E·V' : 'Numérico'}</p>
              </div>
              <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${t.status === 'active' ? 'bg-emerald-900/50 text-emerald-400' : 'bg-slate-700 text-slate-400'}`}>
                {t.status === 'active' ? 'Activo' : 'Próximo'}
              </span>
            </div>
          ))}
        </Card>

        {/* Quick actions */}
        <div className="grid grid-cols-2 gap-3">
          {ACTIONS.map(a => (
            <button
              key={a.path}
              onClick={() => navigate(a.path)}
              className="bg-slate-800 border border-slate-700 rounded-xl p-4 text-left hover:border-slate-500 transition-colors"
            >
              <a.icon size={20} className={`${a.color} mb-2`} />
              <p className="font-semibold text-white text-sm">{a.label}</p>
              <p className="text-xs text-slate-500 mt-0.5">{a.desc}</p>
            </button>
          ))}
        </div>
      </main>
    </div>
  )
}
