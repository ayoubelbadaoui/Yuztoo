export type AppointmentKind = 'call' | 'meeting' | 'demo' | 'followup'

export type Appointment = {
  id: string
  title: string
  kind: AppointmentKind
  /** ISO date-time of the start, local time. */
  start: string
  durationMin: number
  owner: string
  /** Lead this appointment belongs to, so the agenda can link back. */
  leadId: string
  leadName: string
  location?: string
}

export const appointmentKindLabels: Record<AppointmentKind, string> = {
  call: 'Appel',
  meeting: 'Rendez-vous',
  demo: 'Démo',
  followup: 'Relance',
}

export const dayStartHour = 8
export const dayEndHour = 20

/** Les aides de date vivent dans `lib/dates` : l'agenda et le marketing les partagent. */
export {
  addDays,
  formatDayLabel,
  formatMonthLabel,
  formatTime,
  isSameDay,
  monthGridDays,
  startOfDay,
  startOfWeek,
  weekdayLabels,
} from '@/lib/dates'

export function endOf(appointment: Appointment): Date {
  return new Date(
    new Date(appointment.start).getTime() + appointment.durationMin * 60_000,
  )
}
