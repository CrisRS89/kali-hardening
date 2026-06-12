const DOT_COLORS = {
  W: 'bg-emerald-500',
  D: 'bg-amber-400',
  L: 'bg-red-500',
}
const DOT_LABELS = { W: 'G', D: 'E', L: 'P' }

export function TeamFormBar({ form = [] }) {
  return (
    <div className="flex items-center gap-1">
      {form.slice(-5).map((result, i) => (
        <span
          key={i}
          title={result === 'W' ? 'Ganó' : result === 'D' ? 'Empató' : 'Perdió'}
          className={`${DOT_COLORS[result] ?? 'bg-slate-600'} w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-bold text-white`}
        >
          {DOT_LABELS[result] ?? '?'}
        </span>
      ))}
    </div>
  )
}
