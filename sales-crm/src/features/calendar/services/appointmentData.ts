import type {
  Appointment,
  AppointmentKind,
} from '@/features/calendar/domain/appointment'
import { startOfDay } from '@/features/calendar/domain/appointment'
import { mockLeads } from '@/features/leads/services/leadData'

type Row = [
  leadIndex: number,
  dayOffset: number,
  hour: number,
  minute: number,
  durationMin: number,
  kind: AppointmentKind,
  location: string,
]

const rows: Row[] = [
  [0, -9, 10, 0, 45, 'meeting', 'Boutique'],
  [2, -7, 14, 30, 30, 'call', 'Téléphone'],
  [7, -6, 9, 30, 60, 'demo', 'Visio'],
  [12, -4, 16, 0, 30, 'followup', 'Téléphone'],
  [4, -3, 11, 0, 45, 'meeting', 'Boutique'],
  [1, -1, 15, 0, 30, 'call', 'Téléphone'],
  [8, 0, 9, 0, 60, 'demo', 'Visio'],
  [0, 0, 11, 30, 45, 'meeting', 'Boutique'],
  [19, 0, 14, 0, 30, 'call', 'Téléphone'],
  [22, 0, 16, 30, 45, 'meeting', 'Agence Paris'],
  [3, 1, 10, 0, 30, 'followup', 'Téléphone'],
  [15, 1, 15, 30, 60, 'demo', 'Visio'],
  [9, 2, 9, 30, 30, 'call', 'Téléphone'],
  [21, 2, 14, 0, 45, 'meeting', 'Boutique'],
  [5, 3, 11, 0, 30, 'followup', 'Téléphone'],
  [13, 4, 10, 30, 60, 'demo', 'Visio'],
  [24, 4, 16, 0, 30, 'call', 'Téléphone'],
  [10, 5, 9, 0, 45, 'meeting', 'Agence Lyon'],
  [17, 7, 14, 30, 60, 'demo', 'Visio'],
  [6, 8, 11, 0, 30, 'followup', 'Téléphone'],
  [20, 10, 10, 0, 45, 'meeting', 'Boutique'],
  [16, 12, 15, 0, 30, 'call', 'Téléphone'],
  [11, 14, 9, 30, 60, 'demo', 'Visio'],
  [23, 17, 11, 30, 45, 'meeting', 'Agence Marseille'],
]

const titles: Record<AppointmentKind, string> = {
  call: 'Appel de qualification',
  meeting: 'Rendez-vous commercial',
  demo: 'Démo Yuztoo',
  followup: 'Relance',
}

function at(dayOffset: number, hour: number, minute: number): string {
  const date = startOfDay(new Date())
  date.setDate(date.getDate() + dayOffset)
  date.setHours(hour, minute, 0, 0)
  return date.toISOString()
}

/** Temporary dataset, anchored on today so the calendar is never empty. */
export const mockAppointments: Appointment[] = rows.map(
  ([leadIndex, dayOffset, hour, minute, durationMin, kind, location], index) => {
    const lead = mockLeads[leadIndex]
    return {
      id: `AP-${200 + index}`,
      title: titles[kind],
      kind,
      start: at(dayOffset, hour, minute),
      durationMin,
      owner: lead.owner === 'Non assigné' ? 'Sara M.' : lead.owner,
      leadId: lead.id,
      leadName: lead.name,
      location,
    }
  },
)
