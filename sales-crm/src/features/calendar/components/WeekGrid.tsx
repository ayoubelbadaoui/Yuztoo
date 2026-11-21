import type { Appointment } from '@/features/calendar/domain/appointment'
import {
  dayEndHour,
  dayStartHour,
  isSameDay,
  weekdayLabels,
} from '@/features/calendar/domain/appointment'
import { AppointmentChip } from '@/features/calendar/components/AppointmentChip'
import { groupByDay } from '@/features/calendar/services/appointmentService'

const HOUR_HEIGHT = 48
const hours = Array.from(
  { length: dayEndHour - dayStartHour },
  (_, index) => dayStartHour + index,
)

type Props = {
  days: Date[]
  appointments: Appointment[]
  selectedDay: Date
  onSelect: (day: Date) => void
}

/** Minutes from the top of the visible day, used to position a block. */
function offsetMinutes(start: Date): number {
  return (start.getHours() - dayStartHour) * 60 + start.getMinutes()
}

export function WeekGrid({
  days,
  appointments,
  selectedDay,
  onSelect,
}: Props) {
  const grouped = groupByDay(appointments, days)
  const today = new Date()

  return (
    <div className="flex min-h-[26rem] flex-1 flex-col overflow-hidden rounded-xl border border-border">
      <div className="grid shrink-0 grid-cols-[48px_repeat(7,1fr)] border-b border-border bg-muted/40">
        <div />
        {days.map((day) => {
          const isToday = isSameDay(day, today)
          return (
            <button
              key={day.toISOString()}
              type="button"
              onClick={() => onSelect(day)}
              className={`flex items-center justify-center gap-1.5 border-l border-border py-1.5 text-[11px] transition-colors hover:bg-muted ${
                isSameDay(day, selectedDay) ? 'bg-muted' : ''
              }`}
            >
              <span className="text-muted-foreground">
                {weekdayLabels[(day.getDay() + 6) % 7]}
              </span>
              <span
                className={`flex size-5 items-center justify-center rounded-full tabular-nums ${
                  isToday
                    ? 'bg-primary font-semibold text-primary-foreground'
                    : 'text-foreground'
                }`}
              >
                {day.getDate()}
              </span>
            </button>
          )
        })}
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto">
        <div className="grid grid-cols-[48px_repeat(7,1fr)]">
          <div>
            {hours.map((hour) => (
              <div
                key={hour}
                style={{ height: HOUR_HEIGHT }}
                className="pr-1.5 text-right text-[10px] tabular-nums text-muted-foreground"
              >
                {`${hour}h`}
              </div>
            ))}
          </div>

          {days.map((day) => (
            <div
              key={day.toISOString()}
              className="relative border-l border-border"
              style={{ height: hours.length * HOUR_HEIGHT }}
            >
              {hours.map((hour) => (
                <div
                  key={hour}
                  style={{ height: HOUR_HEIGHT }}
                  className="border-b border-border/60"
                />
              ))}

              {(grouped.get(day.toDateString()) ?? []).map((appointment) => {
                const start = new Date(appointment.start)
                return (
                  <div
                    key={appointment.id}
                    className="absolute inset-x-0.5"
                    style={{
                      top: (offsetMinutes(start) / 60) * HOUR_HEIGHT,
                      height: Math.max(
                        (appointment.durationMin / 60) * HOUR_HEIGHT,
                        22,
                      ),
                    }}
                  >
                    <AppointmentChip appointment={appointment} compact />
                  </div>
                )
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
