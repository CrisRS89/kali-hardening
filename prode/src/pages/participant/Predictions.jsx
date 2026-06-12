import { useState } from 'react'
import { ArrowLeft, Clock, Zap } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { mockMatches, mockTournaments } from '../../data/mockData'
import { TeamFormBar } from '../../components/matches/TeamFormBar'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'
import { useToast } from '../../context/ToastContext'

function LEVSelector({ value, onChange }) {
  const opts = [
    { key: 'L', label: 'L', title: 'Local' },
    { key: 'E', label: 'E', title: 'Empate' },
    { key: 'V', label: 'V', title: 'Visitante' },
  ]
  return (
    <div className="flex gap-1.5">
      {opts.map(o => (
        <button
          key={o.key}
          title={o.title}
          onClick={() => onChange(value === o.key ? null : o.key)}
          className={`w-9 h-9 rounded-lg text-sm font-bold border transition-all ${
            value === o.key
              ? 'bg-brand-600 border-brand-500 text-white shadow-md shadow-brand-900/50'
              : 'bg-slate-700 border-slate-600 text-slate-400 hover:border-slate-500 hover:text-white'
          }`}
        >
          {o.label}
        </button>
      ))}
    </div>
  )
}

function NumericSelector({ home, away, onHome, onAway }) {
  const cls = 'w-10 h-10 bg-slate-700 border border-slate-600 rounded-lg text-center text-white text-base font-bold focus:outline-none focus:border-brand-500'
  return (
    <div className="flex items-center gap-2">
      <input type="number" min="0" max="20" value={home ?? ''} onChange={e => onHome(e.target.value === '' ? null : Number(e.target.value))} placeholder="0" className={cls} />
      <span className="text-slate-500 font-bold">-</span>
      <input type="number" min="0" max="20" value={away ?? ''} onChange={e => onAway(e.target.value === '' ? null : Number(e.target.value))} placeholder="0" className={cls} />
    </div>
  )
}

export default function Predictions() {
  const navigate = useNavigate()
  const { push } = useToast()
  const tournament = mockTournaments[0]
  const matches = mockMatches.filter(m => m.tournamentId === tournament.id)
  const isNumeric = tournament.predictionMode === 'numeric'

  const [predictions, setPredictions] = useState({})
  const [saved, setSaved] = useState(false)

  function updateLEV(matchId, val) {
    setPredictions(p => ({ ...p, [matchId]: { type: 'LEV', value: val } }))
    setSaved(false)
  }

  function updateScore(matchId, side, val) {
    setPredictions(p => ({
      ...p,
      [matchId]: { ...p[matchId], type: 'numeric', [side]: val },
    }))
    setSaved(false)
  }

  function handleSave() {
    const filled = matches.filter(m => {
      const p = predictions[m.id]
      if (!p) return false
      if (isNumeric) return p.home !== undefined && p.away !== undefined
      return !!p.value
    })
    if (filled.length === 0) { push('Ingresá al menos un pronóstico', 'error'); return }
    setSaved(true)
    push(`${filled.length} pronóstico${filled.length > 1 ? 's' : ''} guardado${filled.length > 1 ? 's' : ''}`, 'success')
  }

  const statusColors = { scheduled: 'text-slate-500', live: 'text-red-400', finished: 'text-emerald-400' }

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col">
      <header className="bg-slate-800 border-b border-slate-700 px-4 py-3 flex items-center gap-3">
        <button onClick={() => navigate('/dashboard')} className="text-slate-400 hover:text-white"><ArrowLeft size={20} /></button>
        <div>
          <h1 className="font-bold text-white text-sm">{tournament.name}</h1>
          <div className="flex items-center gap-1.5 text-xs text-slate-500">
            <Clock size={12} />
            Cierra: {new Date(tournament.closesAt).toLocaleString('es-AR')}
            <span className={`ml-2 font-semibold uppercase text-[10px] px-1.5 py-0.5 rounded-full bg-slate-700 ${isNumeric ? 'text-purple-400' : 'text-brand-400'}`}>
              {isNumeric ? 'Numérico' : 'L · E · V'}
            </span>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-4 space-y-3">
        {matches.map(m => {
          const p = predictions[m.id] ?? {}
          return (
            <Card key={m.id} className="space-y-3">
              {/* Status */}
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-500">
                  {new Date(m.date).toLocaleString('es-AR', { weekday: 'short', hour: '2-digit', minute: '2-digit' })}
                </span>
                {m.status === 'live' && (
                  <span className="flex items-center gap-1 text-red-400 font-semibold">
                    <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
                    EN VIVO {m.homeScore} - {m.awayScore}
                  </span>
                )}
              </div>

              {/* Teams */}
              <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-3">
                {/* Home */}
                <div className="space-y-1">
                  <p className="font-bold text-white text-sm">{m.homeTeam.name}</p>
                  <TeamFormBar form={m.homeTeam.form} />
                </div>

                <div className="text-slate-600 font-bold text-sm">vs</div>

                {/* Away */}
                <div className="space-y-1 text-right">
                  <p className="font-bold text-white text-sm">{m.awayTeam.name}</p>
                  <div className="flex justify-end">
                    <TeamFormBar form={m.awayTeam.form} />
                  </div>
                </div>
              </div>

              {/* Prediction input */}
              <div className="flex justify-center pt-1 border-t border-slate-700">
                {isNumeric ? (
                  <NumericSelector
                    home={p.home}
                    away={p.away}
                    onHome={v => updateScore(m.id, 'home', v)}
                    onAway={v => updateScore(m.id, 'away', v)}
                  />
                ) : (
                  <LEVSelector value={p.value} onChange={v => updateLEV(m.id, v)} />
                )}
              </div>
            </Card>
          )
        })}

        <Button
          className="w-full justify-center gap-2"
          onClick={handleSave}
        >
          <Zap size={16} />
          {saved ? '✓ Pronósticos guardados' : 'Guardar pronósticos'}
        </Button>
      </main>
    </div>
  )
}
