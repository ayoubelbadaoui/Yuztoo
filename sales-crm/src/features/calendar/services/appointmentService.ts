import type { Appointment } from '@/features/calendar/domain/appointment'
import { addDays, isSameDay, startOfDay } from '@/features/calendar/domain/appointment'
import { mockAppointments } from '@/features/calendar/services/appointmentData'

type Result<T> = { data: T | null; error: Error | null }

function byStart(a: Appointment, b: Appointment): number {
  return a.start.localeCompare(b.start)
}

/** Everything that intersects [from, to), so a view can ask for a month or a week. */
export async function getAppointmentsBetween(
  from: Date,
  to: Date,
): Promise<Result<Appointment[]>> {
  try {
    const start = from.getTime()
    const end = to.getTime()
    const data = mockAppointments
      .filter((appointment) => {
        const at = new Date(appointment.start).getTime()
        return at >= start && at < end
      })
      .sort(byStart)
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getAppointmentsForDay(
  day: Date,
): Promise<Result<Appointment[]>> {
  return getAppointmentsBetween(startOfDay(day), addDays(startOfDay(day), 1))
}

export function groupByDay(
  appointments: Appointment[],
  days: Date[],
): Map<string, Appointment[]> {
  const grouped = new Map<string, Appointment[]>()
  for (const day of days) {
    grouped.set(
      day.toDateString(),
      appointments.filter((appointment) =>
        isSameDay(new Date(appointment.start), day),
      ),
    )
  }
  return grouped
}
