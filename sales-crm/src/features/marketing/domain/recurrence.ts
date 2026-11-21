export type RecurrenceFreq = 'once' | 'daily' | 'every_n_days' | 'weekly'

export const recurrenceFreqLabels: Record<RecurrenceFreq, string> = {
  once: 'Une seule fois',
  daily: 'Tous les jours',
  every_n_days: 'Tous les N jours',
  weekly: 'Une fois par semaine',
}

export type RecurrenceRule = {
  freq: RecurrenceFreq
  /** Used when freq = every_n_days (default 2). */
  interval: number
  /** 0=Sun … 6=Sat when freq = weekly. */
  byWeekday: number[]
  timeOfDay: string
  timezone: string
  startsOn: string | null
  endsOn: string | null
  maxOccurrences: number | null
}

export const defaultRecurrence = (): RecurrenceRule => ({
  freq: 'once',
  interval: 1,
  byWeekday: [],
  timeOfDay: '09:00',
  timezone: 'Europe/Paris',
  startsOn: null,
  endsOn: null,
  maxOccurrences: null,
})

/** Next occurrence dates (UTC ISO), capped for safety. */
export function expandOccurrences(
  rule: RecurrenceRule,
  firstAt: Date,
  limit = 30,
): Date[] {
  const max = Math.min(rule.maxOccurrences ?? limit, 52, limit)
  if (rule.freq === 'once') return [firstAt]

  const out: Date[] = []
  let cursor = new Date(firstAt)
  const end = rule.endsOn ? new Date(`${rule.endsOn}T23:59:59`) : null

  while (out.length < max) {
    if (end && cursor > end) break
    out.push(new Date(cursor))

    if (rule.freq === 'daily') {
      cursor = addDays(cursor, 1)
    } else if (rule.freq === 'every_n_days') {
      cursor = addDays(cursor, Math.max(1, rule.interval))
    } else if (rule.freq === 'weekly') {
      cursor = nextWeekday(cursor, rule.byWeekday.length ? rule.byWeekday : [cursor.getDay()])
    } else {
      break
    }
  }
  return out
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date)
  next.setDate(next.getDate() + days)
  return next
}

function nextWeekday(from: Date, weekdays: number[]): Date {
  const sorted = [...new Set(weekdays)].sort((a, b) => a - b)
  const start = addDays(from, 1)
  for (let i = 0; i < 14; i += 1) {
    const candidate = addDays(start, i)
    if (sorted.includes(candidate.getDay())) return candidate
  }
  return addDays(from, 7)
}
