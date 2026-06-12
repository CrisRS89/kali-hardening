export const mockTournaments = [
  {
    id: 1,
    name: 'Liga Prode 2025 — Fecha 1',
    league: 'Liga Argentina',
    status: 'active',
    predictionMode: 'LEV',
    pointsPerResult: 3,
    pointsExactScore: 0,
    closesAt: '2025-08-10T20:00:00',
    participants: 24,
  },
  {
    id: 2,
    name: 'Champions League — Jornada 3',
    league: 'UEFA Champions League',
    status: 'upcoming',
    predictionMode: 'numeric',
    pointsPerResult: 2,
    pointsExactScore: 3,
    closesAt: '2025-09-15T18:00:00',
    participants: 18,
  },
]

export const mockMatches = [
  {
    id: 101, tournamentId: 1,
    homeTeam: { id: 1, name: 'Boca Juniors', shortName: 'BOC', crest: '🔵🟡', form: ['W','W','D','L','W'] },
    awayTeam: { id: 2, name: 'River Plate', shortName: 'RIV', crest: '🔴⚪', form: ['W','D','W','W','D'] },
    date: '2025-08-10T21:00:00', status: 'scheduled', homeScore: null, awayScore: null,
  },
  {
    id: 102, tournamentId: 1,
    homeTeam: { id: 3, name: 'Racing Club', shortName: 'RAC', crest: '🔵⚪', form: ['D','W','W','D','W'] },
    awayTeam: { id: 4, name: 'Independiente', shortName: 'IND', crest: '🔴', form: ['L','D','W','L','D'] },
    date: '2025-08-10T19:00:00', status: 'scheduled', homeScore: null, awayScore: null,
  },
  {
    id: 103, tournamentId: 1,
    homeTeam: { id: 5, name: 'San Lorenzo', shortName: 'SL', crest: '🔵🔴', form: ['W','L','D','W','W'] },
    awayTeam: { id: 6, name: 'Huracán', shortName: 'HUR', crest: '🟡⚫', form: ['D','L','D','D','L'] },
    date: '2025-08-11T18:30:00', status: 'live', homeScore: 1, awayScore: 0,
  },
]

export const mockRanking = [
  { rank: 1, userId: 2, name: 'Juan Pérez', pts: 42, xp: 2800, level: 5, streak: 7, avatar: '🧔' },
  { rank: 2, userId: 3, name: 'María García', pts: 38, xp: 2400, level: 4, streak: 4, avatar: '👩' },
  { rank: 3, userId: 4, name: 'Carlos López', pts: 35, xp: 2100, level: 4, streak: 2, avatar: '🧑' },
  { rank: 4, userId: 5, name: 'Ana Martínez', pts: 31, xp: 1900, level: 3, streak: 0, avatar: '👩‍🦰' },
]

export const mockUser = {
  id: 2,
  name: 'Juan Pérez',
  email: 'juan@prode.com',
  role: 'participante',
  avatar: '🧔',
  xp: 2800,
  level: 5,
  xpNextLevel: 3000,
  streak: 7,
  peakStreak: 12,
  pts: 42,
  rank: 1,
  powerUps: { doublePoints: 1, shield: 1 },
  badges: ['first_prediction', 'streak_5', 'perfect_date', 'early_bird'],
}

export const mockNews = [
  {
    id: 1,
    title: 'Boca Juniors refuerza su delantera para el segundo semestre',
    source: 'TyC Sports',
    publishedAt: '2025-08-09T10:00:00',
    url: '#',
    imageUrl: null,
    summary: 'El Xeneize cerró la incorporación de un delantero brasileño que llega a préstamo.',
  },
  {
    id: 2,
    title: 'La Liga Argentina define el fixture de la próxima fecha',
    source: 'Olé',
    publishedAt: '2025-08-09T08:30:00',
    url: '#',
    imageUrl: null,
    summary: 'AFA confirmó los horarios de los partidos para la jornada 12 del torneo Apertura.',
  },
  {
    id: 3,
    title: 'Champions League: Manchester City aplastó al PSG en el Etihad',
    source: 'Marca',
    publishedAt: '2025-08-08T22:15:00',
    url: '#',
    imageUrl: null,
    summary: 'Goleada histórica en la primera jornada de la fase de grupos con hat-trick de Haaland.',
  },
]
