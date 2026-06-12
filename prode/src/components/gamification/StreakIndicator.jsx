import { Flame } from 'lucide-react'

export function StreakIndicator({ streak }) {
  const color = streak >= 10 ? 'text-amber-400' : streak >= 5 ? 'text-orange-400' : 'text-slate-400'
  return (
    <div className={`flex items-center gap-1 font-bold ${color}`}>
      <Flame size={16} className={streak > 0 ? 'animate-pulse-slow' : ''} />
      <span className="text-sm">{streak}</span>
    </div>
  )
}
