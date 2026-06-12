import { useState } from 'react'
import { ArrowLeft, Download, Loader } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { LEAGUES } from '../../data/leagues'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'
import { useToast } from '../../context/ToastContext'

const MOCK_IMPORTED = [
  { home: 'Boca Juniors', away: 'River Plate', date: '2025-08-10T21:00:00' },
  { home: 'Racing Club', away: 'Independiente', date: '2025-08-10T19:00:00' },
  { home: 'San Lorenzo', away: 'Huracán', date: '2025-08-11T18:30:00' },
  { home: 'Vélez Sársfield', away: 'Estudiantes', date: '2025-08-11T20:00:00' },
]

export default function ImportMatches() {
  const navigate = useNavigate()
  const { push } = useToast()
  const [selected, setSelected] = useState(null)
  const [loading, setLoading] = useState(false)
  const [imported, setImported] = useState(null)

  async function handleImport(league) {
    setSelected(league.id)
    setLoading(true)
    await new Promise(r => setTimeout(r, 1200))
    setLoading(false)
    setImported({ league, matches: MOCK_IMPORTED })
    push(`${MOCK_IMPORTED.length} partidos importados de ${league.name}`, 'success')
  }

  function handleConfirm() {
    push('Partidos agregados al torneo activo', 'success')
    navigate('/admin')
  }

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col">
      <header className="bg-slate-800 border-b border-slate-700 px-4 py-3 flex items-center gap-3">
        <button onClick={() => navigate('/admin')} className="text-slate-400 hover:text-white"><ArrowLeft size={20} /></button>
        <h1 className="font-bold text-white">Importar partidos</h1>
      </header>

      <main className="max-w-lg mx-auto w-full px-4 py-4 space-y-4">

        <p className="text-sm text-slate-400">Seleccioná una liga para importar los próximos partidos automáticamente.</p>

        {/* League selector */}
        <div className="grid grid-cols-2 gap-3">
          {LEAGUES.map(l => (
            <button
              key={l.id}
              onClick={() => !loading && handleImport(l)}
              className={`bg-slate-800 border rounded-xl px-4 py-3 flex items-center gap-3 transition-all text-left ${
                selected === l.id ? 'border-brand-500' : 'border-slate-700 hover:border-slate-500'
              }`}
            >
              <span className="text-2xl">{l.flag}</span>
              <div>
                <p className="text-sm font-medium text-white leading-tight">{l.name}</p>
              </div>
              {loading && selected === l.id && <Loader size={16} className="ml-auto text-brand-400 animate-spin" />}
            </button>
          ))}
        </div>

        {/* Imported preview */}
        {imported && (
          <Card>
            <h3 className="font-semibold text-white text-sm mb-3">
              {imported.league.flag} {imported.league.name} — {imported.matches.length} partidos
            </h3>
            <div className="space-y-2 mb-4">
              {imported.matches.map((m, i) => (
                <div key={i} className="flex items-center justify-between text-sm">
                  <span className="text-white">{m.home} <span className="text-slate-500">vs</span> {m.away}</span>
                  <span className="text-xs text-slate-500">
                    {new Date(m.date).toLocaleString('es-AR', { weekday: 'short', hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              ))}
            </div>
            <Button className="w-full justify-center" onClick={handleConfirm}>
              <Download size={16} />
              Confirmar e importar
            </Button>
          </Card>
        )}
      </main>
    </div>
  )
}
