import { getLevelInfo } from '../../data/badges'

export function XPBar({ xp, compact = false }) {
  const info = getLevelInfo(xp)

  if (compact) {
    return (
      <div className="flex items-center gap-2 min-w-0">
        <span className="text-base">{info.icon}</span>
        <div className="flex-1 min-w-0">
          <div className="flex justify-between text-xs text-slate-400 mb-0.5">
            <span>{info.label}</span>
            <span className="text-xp font-bold">{xp} XP</span>
          </div>
          <div className="h-1.5 bg-slate-700 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-amber-500 to-yellow-400 rounded-full transition-all duration-500"
              style={{ width: `${info.progress}%` }}
            />
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-sm">
        <span className="flex items-center gap-1.5 font-semibold text-white">
          {info.icon} Nivel {info.level} — {info.label}
        </span>
        <span className="text-xp font-bold">{xp} XP</span>
      </div>
      <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
        <div
          className="h-full bg-gradient-to-r from-amber-500 to-yellow-400 rounded-full transition-all duration-700"
          style={{ width: `${info.progress}%` }}
        />
      </div>
      {info.nextLevel && (
        <p className="text-xs text-slate-500 text-right">{info.xpToNext} XP para {info.nextLevel.label}</p>
      )}
    </div>
  )
}
