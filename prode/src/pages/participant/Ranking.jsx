import { ArrowLeft, Trophy } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { mockRanking } from '../../data/mockData'
import { StreakIndicator } from '../../components/gamification/StreakIndicator'
import { getLevelInfo } from '../../data/badges'

const MEDAL = { 1: '🥇', 2: '🥈', 3: '🥉' }

export default function Ranking() {
  const navigate = useNavigate()
  return (
    <div className="min-h-screen bg-slate-900 flex flex-col">
      <header className="bg-slate-800 border-b border-slate-700 px-4 py-3 flex items-center gap-3">
        <button onClick={() => navigate('/dashboard')} className="text-slate-400 hover:text-white"><ArrowLeft size={20} /></button>
        <h1 className="font-bold text-white">Ranking General</h1>
      </header>
      <main className="max-w-lg mx-auto w-full px-4 py-4 space-y-2">
        {mockRanking.map(r => {
          const lvl = getLevelInfo(r.xp)
          return (
            <div
              key={r.userId}
              className={`bg-slate-800 border rounded-xl px-4 py-3 flex items-center gap-3 ${
                r.rank <= 3 ? 'border-amber-700/50' : 'border-slate-700'
              }`}
            >
              <span className="text-xl w-8 text-center">{MEDAL[r.rank] ?? `#${r.rank}`}</span>
              <span className="text-xl">{r.avatar}</span>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-white text-sm truncate">{r.name}</p>
                <div className="flex items-center gap-2 text-xs text-slate-500">
                  <span>{lvl.icon} {lvl.label}</span>
                  <StreakIndicator streak={r.streak} />
                </div>
              </div>
              <div className="text-right shrink-0">
                <p className="text-lg font-extrabold text-brand-400">{r.pts}</p>
                <p className="text-xs text-slate-500">pts</p>
              </div>
            </div>
          )
        })}
      </main>
    </div>
  )
}
