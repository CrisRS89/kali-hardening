import { useNavigate } from 'react-router-dom'
import { Trophy, Calendar, BarChart2, Users, LogOut, Sun, Moon, Bell } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { useTheme } from '../../context/ThemeContext'
import { XPBar } from '../../components/gamification/XPBar'
import { StreakIndicator } from '../../components/gamification/StreakIndicator'
import { BadgeGrid } from '../../components/gamification/BadgeGrid'
import { mockUser, mockRanking, mockNews } from '../../data/mockData'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'

const NAV = [
  { label: 'Pronósticos', icon: Calendar, path: '/dashboard/pronosticos', color: 'text-brand-400' },
  { label: 'Ranking',     icon: Trophy,   path: '/dashboard/ranking',     color: 'text-amber-400' },
  { label: 'Estadísticas',icon: BarChart2, path: '/dashboard/estadisticas', color: 'text-purple-400' },
  { label: 'Grupos',      icon: Users,    path: '/dashboard/grupos',      color: 'text-emerald-400' },
]

export default function Dashboard() {
  const { user, logout } = useAuth()
  const { dark, toggle } = useTheme()
  const navigate = useNavigate()
  const u = mockUser

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col">

      {/* Header */}
      <header className="bg-slate-800 border-b border-slate-700 px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-brand-600 flex items-center justify-center text-lg">
            {u.avatar}
          </div>
          <div>
            <p className="text-sm font-semibold text-white">{user?.name}</p>
            <div className="flex items-center gap-2">
              <StreakIndicator streak={u.streak} />
              <span className="text-xs text-slate-500">racha</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button className="p-1.5 rounded-lg hover:bg-slate-700 text-slate-400 hover:text-white relative">
            <Bell size={18} />
            <span className="absolute top-0.5 right-0.5 w-2 h-2 bg-red-500 rounded-full" />
          </button>
          <button onClick={toggle} className="p-1.5 rounded-lg hover:bg-slate-700 text-slate-400 hover:text-white">
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <button onClick={() => { logout(); navigate('/') }} className="p-1.5 rounded-lg hover:bg-slate-700 text-slate-400 hover:text-red-400">
            <LogOut size={18} />
          </button>
        </div>
      </header>

      <main className="flex-1 max-w-2xl mx-auto w-full px-4 py-6 space-y-4">

        {/* XP Bar */}
        <Card>
          <XPBar xp={u.xp} />
        </Card>

        {/* Stats row */}
        <div className="grid grid-cols-3 gap-3">
          {[
            { label: 'Puntos', value: u.pts, color: 'text-brand-400' },
            { label: 'Rank',   value: `#${u.rank}`, color: 'text-amber-400' },
            { label: 'Racha',  value: u.streak, color: 'text-orange-400' },
          ].map(s => (
            <Card key={s.label} className="text-center py-3">
              <p className={`text-2xl font-extrabold ${s.color}`}>{s.value}</p>
              <p className="text-xs text-slate-500 mt-0.5">{s.label}</p>
            </Card>
          ))}
        </div>

        {/* Navigation */}
        <div className="grid grid-cols-2 gap-3">
          {NAV.map(n => (
            <button
              key={n.path}
              onClick={() => navigate(n.path)}
              className="bg-slate-800 border border-slate-700 rounded-xl p-4 flex items-center gap-3 hover:border-slate-500 transition-colors text-left"
            >
              <n.icon size={20} className={n.color} />
              <span className="font-medium text-white text-sm">{n.label}</span>
            </button>
          ))}
        </div>

        {/* Badges preview */}
        <Card>
          <h3 className="font-semibold text-white text-sm mb-3 flex items-center justify-between">
            Mis insignias
            <span className="text-xs text-slate-500">{u.badges.length} desbloqueadas</span>
          </h3>
          <BadgeGrid earnedIds={u.badges} compact />
        </Card>

        {/* Top ranking preview */}
        <Card>
          <h3 className="font-semibold text-white text-sm mb-3">Ranking — Top 3</h3>
          <div className="space-y-2">
            {mockRanking.slice(0, 3).map(r => (
              <div key={r.userId} className="flex items-center gap-3">
                <span className={`w-5 text-xs font-bold text-center ${r.rank === 1 ? 'text-amber-400' : r.rank === 2 ? 'text-slate-300' : 'text-amber-700'}`}>
                  #{r.rank}
                </span>
                <span className="text-base">{r.avatar}</span>
                <span className="flex-1 text-sm text-white">{r.name}</span>
                <span className="text-sm font-bold text-brand-400">{r.pts} pts</span>
              </div>
            ))}
          </div>
          <Button variant="ghost" className="w-full justify-center mt-3 text-xs" onClick={() => navigate('/dashboard/ranking')}>
            Ver ranking completo →
          </Button>
        </Card>

        {/* Latest news preview */}
        <Card>
          <h3 className="font-semibold text-white text-sm mb-3">Últimas noticias</h3>
          <div className="space-y-3">
            {mockNews.slice(0, 2).map(n => (
              <div key={n.id} className="border-b border-slate-700 last:border-0 pb-2 last:pb-0">
                <p className="text-xs font-medium text-white leading-snug">{n.title}</p>
                <p className="text-xs text-slate-500 mt-0.5">{n.source}</p>
              </div>
            ))}
          </div>
        </Card>
      </main>
    </div>
  )
}
