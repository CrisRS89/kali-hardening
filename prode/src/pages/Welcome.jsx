import { useNavigate } from 'react-router-dom'
import { Sun, Moon, Trophy, Users, Settings, Zap, Star, Flame } from 'lucide-react'
import { useTheme } from '../context/ThemeContext'
import { Button } from '../components/ui/Button'

const FEATURES = [
  { icon: <Zap size={18} className="text-amber-400" />, label: 'Sistema de XP y niveles' },
  { icon: <Flame size={18} className="text-orange-400" />, label: 'Racha de aciertos' },
  { icon: <Star size={18} className="text-purple-400" />, label: 'Insignias y logros' },
  { icon: <Trophy size={18} className="text-brand-400" />, label: 'Ranking en tiempo real' },
]

const LIVE_MATCHES = [
  { home: 'San Lorenzo', away: 'Huracán', score: '1 - 0', min: "73'" },
]

export default function Welcome() {
  const navigate = useNavigate()
  const { dark, toggle } = useTheme()

  return (
    <div className="min-h-screen bg-slate-900 dark:bg-slate-900 light:bg-slate-50 flex flex-col">

      {/* Top bar */}
      <header className="flex items-center justify-between px-6 py-4 border-b border-slate-800">
        <div className="flex items-center gap-2">
          <Trophy size={22} className="text-brand-500" />
          <span className="font-bold text-white tracking-wide text-sm uppercase">Sistema Prode</span>
        </div>
        <button
          onClick={toggle}
          className="p-2 rounded-lg hover:bg-slate-800 transition-colors text-slate-400 hover:text-white"
          aria-label="Cambiar tema"
        >
          {dark ? <Sun size={18} /> : <Moon size={18} />}
        </button>
      </header>

      {/* Hero */}
      <main className="flex-1 flex flex-col items-center justify-center px-4 py-12 gap-10">

        {/* Logo block */}
        <div className="text-center space-y-4 max-w-lg">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-gradient-to-br from-brand-600 to-brand-700 shadow-xl shadow-brand-900/50 mb-2">
            <Trophy size={40} className="text-white" />
          </div>
          <h1 className="text-4xl sm:text-5xl font-extrabold text-white tracking-tight leading-tight">
            PRODE
          </h1>
          <p className="text-slate-400 text-lg leading-relaxed">
            Competí con tus pronósticos, ganá XP,<br />
            desbloqueá insignias y subí en el ranking.
          </p>

          {/* Feature pills */}
          <div className="flex flex-wrap justify-center gap-2 pt-2">
            {FEATURES.map((f, i) => (
              <span
                key={i}
                className="flex items-center gap-1.5 bg-slate-800 border border-slate-700 rounded-full px-3 py-1 text-xs text-slate-300"
              >
                {f.icon} {f.label}
              </span>
            ))}
          </div>
        </div>

        {/* Role cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full max-w-xl">

          {/* Participante */}
          <div className="bg-slate-800 border border-slate-700 rounded-2xl p-6 flex flex-col gap-4 hover:border-brand-500 transition-colors group">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-brand-600/20 flex items-center justify-center">
                <Users size={20} className="text-brand-400" />
              </div>
              <div>
                <h2 className="font-bold text-white text-base">Participante</h2>
                <p className="text-xs text-slate-500">Pronósticos y ranking</p>
              </div>
            </div>
            <p className="text-sm text-slate-400 leading-relaxed">
              Ingresá tus pronósticos, acumulá puntos reales y XP, y competí contra todos los participantes.
            </p>
            <div className="flex flex-col gap-2 mt-auto">
              <Button
                className="w-full justify-center"
                onClick={() => navigate('/auth/login?role=participante')}
              >
                Ingresar →
              </Button>
              <Button
                variant="ghost"
                className="w-full justify-center text-slate-400 hover:text-white"
                onClick={() => navigate('/auth/register')}
              >
                Registrarme
              </Button>
            </div>
          </div>

          {/* Admin */}
          <div className="bg-slate-800 border border-slate-700 rounded-2xl p-6 flex flex-col gap-4 hover:border-slate-500 transition-colors">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-slate-700 flex items-center justify-center">
                <Settings size={20} className="text-slate-400" />
              </div>
              <div>
                <h2 className="font-bold text-white text-base">Administración</h2>
                <p className="text-xs text-slate-500">Gestión del torneo</p>
              </div>
            </div>
            <p className="text-sm text-slate-400 leading-relaxed">
              Gestioná torneos, importá partidos de las ligas principales, registrá resultados y configurá la gamificación.
            </p>
            <div className="mt-auto">
              <Button
                variant="secondary"
                className="w-full justify-center"
                onClick={() => navigate('/auth/login?role=admin')}
              >
                Ingresar →
              </Button>
            </div>
          </div>
        </div>

        {/* Live ticker */}
        {LIVE_MATCHES.length > 0 && (
          <div className="flex items-center gap-3 bg-slate-800/80 border border-red-900/50 rounded-full px-5 py-2.5 text-sm">
            <span className="flex items-center gap-1.5 text-red-400 font-semibold">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
              LIVE
            </span>
            {LIVE_MATCHES.map((m, i) => (
              <span key={i} className="text-slate-300">
                {m.home} <span className="text-white font-bold">{m.score}</span> {m.away}
                <span className="ml-2 text-slate-500">{m.min}</span>
              </span>
            ))}
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="text-center py-4 px-6 border-t border-slate-800">
        <p className="text-xs text-slate-600">
          Universidad de la Marina Mercante · Análisis de Sistemas II · Cristian R. Sosa
        </p>
      </footer>
    </div>
  )
}
