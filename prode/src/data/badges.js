export const BADGES = {
  first_prediction: { id: 'first_prediction', label: 'Primer Pronóstico', icon: '🎯', desc: 'Cargaste tu primer pronóstico', rarity: 'common' },
  streak_3:        { id: 'streak_3',        label: 'En Racha',          icon: '🔥', desc: '3 aciertos consecutivos',    rarity: 'common' },
  streak_5:        { id: 'streak_5',        label: 'Imparable',         icon: '⚡', desc: '5 aciertos consecutivos',    rarity: 'rare' },
  streak_10:       { id: 'streak_10',       label: 'Leyenda',           icon: '👑', desc: '10 aciertos consecutivos',   rarity: 'epic' },
  perfect_date:    { id: 'perfect_date',    label: 'Fecha Perfecta',    icon: '💎', desc: 'Acertaste todos en una fecha', rarity: 'epic' },
  early_bird:      { id: 'early_bird',      label: 'Madrugador',        icon: '🌅', desc: 'Pronóstico 12h antes del cierre', rarity: 'common' },
  exact_score:     { id: 'exact_score',     label: 'Adivino',           icon: '🔮', desc: '5 marcadores exactos acumulados', rarity: 'rare' },
  top_1:           { id: 'top_1',           label: 'Campeón',           icon: '🏆', desc: 'Primer lugar en un torneo',  rarity: 'legendary' },
  lucky_week:      { id: 'lucky_week',      label: 'Semana de Suerte',  icon: '🍀', desc: 'Top 3 en una semana',        rarity: 'rare' },
}

export const RARITY_COLORS = {
  common:    'border-slate-500 text-slate-400',
  rare:      'border-blue-500 text-blue-400',
  epic:      'border-purple-500 text-purple-400',
  legendary: 'border-amber-500 text-amber-400',
}

export const LEVELS = [
  { level: 1, label: 'Novato',       minXP: 0,    icon: '🥉' },
  { level: 2, label: 'Aprendiz',     minXP: 500,  icon: '🥈' },
  { level: 3, label: 'Competidor',   minXP: 1200, icon: '🥇' },
  { level: 4, label: 'Experto',      minXP: 2000, icon: '⭐' },
  { level: 5, label: 'Maestro',      minXP: 3000, icon: '🌟' },
  { level: 6, label: 'Gran Maestro', minXP: 5000, icon: '👑' },
]

export function getLevelInfo(xp) {
  let current = LEVELS[0]
  for (const l of LEVELS) {
    if (xp >= l.minXP) current = l
  }
  const nextLevel = LEVELS.find(l => l.level === current.level + 1)
  const minXP = current.minXP
  const maxXP = nextLevel ? nextLevel.minXP : current.minXP + 2000
  const progress = Math.min(100, Math.round(((xp - minXP) / (maxXP - minXP)) * 100))
  return { ...current, nextLevel, progress, xpToNext: nextLevel ? nextLevel.minXP - xp : 0 }
}
