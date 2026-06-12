import { BADGES, RARITY_COLORS } from '../../data/badges'

export function BadgeGrid({ earnedIds = [], compact = false }) {
  const all = Object.values(BADGES)

  if (compact) {
    const earned = all.filter(b => earnedIds.includes(b.id))
    return (
      <div className="flex gap-1.5 flex-wrap">
        {earned.slice(0, 6).map(b => (
          <span key={b.id} title={b.label} className="text-lg cursor-default">{b.icon}</span>
        ))}
        {earned.length > 6 && (
          <span className="text-xs text-slate-500 self-center">+{earned.length - 6}</span>
        )}
      </div>
    )
  }

  return (
    <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
      {all.map(b => {
        const earned = earnedIds.includes(b.id)
        return (
          <div
            key={b.id}
            className={`rounded-lg border p-3 text-center transition-all ${
              earned
                ? `${RARITY_COLORS[b.rarity]} bg-slate-800/80`
                : 'border-slate-700 text-slate-600 opacity-40 grayscale'
            }`}
          >
            <div className="text-2xl mb-1">{b.icon}</div>
            <div className="text-xs font-semibold truncate">{b.label}</div>
            <div className="text-xs mt-0.5 opacity-70 line-clamp-2">{b.desc}</div>
          </div>
        )
      })}
    </div>
  )
}
