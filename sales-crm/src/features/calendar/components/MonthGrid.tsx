import type { Appointment } from '@/features/calendar/domain/appointment'
import { isSameDay, weekdayLabels } from '@/features/calendar/domain/appointment'
import { AppointmentChip } from '@/features/calendar/components/AppointmentChip'
import { groupByDay } from '@/features/calendar/services/appointmentService'

const MAX_VISIBLE = 2

type Props = {
  days: Date[]
  anchor: Date
  appointments: Appointment[]
  selectedDay: Date
  onSelect: (day: Date) => void
}

export function MonthGrid({
  days,
  anchor,
  appointments,
  selectedDay,
  onSelect,
}: Props) {
  const grouped = groupByDay(appointments, days)
  const today = new Date()

  return (
    <div className="flex min-h-[32rem] flex-1 flex-col overflow-hidden rounded-xl border border-border">
      <div className="grid grid-cols-7 border-b border-border bg-muted/40">
        {weekdayLabels.map((label) => (
          <div
            key={label}
            className="px-2 py-1.5 text-center text-[11px] font-medium text-muted-foreground"
          >
            {label}
          </div>
        ))}
      </div>

      <div className="grid flex-1 grid-cols-7 grid-rows-6">
        {days.map((day) => {
          const dayAppointments = grouped.get(day.toDateString()) ?? []
          const isCurrentMonth = day.getMonth() === anchor.getMonth()
          const isToday = isSameDay(day, today)
          const isSelected = isSameDay(day, selectedDay)

          return (
            <button
              key={day.toISOString()}
              type="button"
              onClick={() => onSelect(day)}
              aria-current={isToday ? 'date' : undefined}
              className={`flex min-h-20 flex-col gap-1 border-b border-r border-border p-1.5 text-left transition-colors last:border-r-0 ${
                isCurrentMonth ? 'bg-card' : 'bg-muted/30'
              } ${isSelected ? 'ring-1 ring-inset ring-primary' : 'hover:bg-muted/60'}`}
            >
              <span
                className={`flex size-5 items-center justify-center rounded-full text-[11px] tabular-nums ${
                  isToday
                    ? 'bg-primary font-semibold text-primary-foreground'
                    : isCurrentMonth
                      ? 'text-foreground'
                      : 'text-muted-foreground'
                }`}
              >
                {day.getDate()}
              </span>

              <div className="flex flex-col gap-0.5">
                {dayAppointments.slice(0, MAX_VISIBLE).map((appointment) => (
                  <AppointmentChip
                    key={appointment.id}
                    appointment={appointment}
                    compact
                  />
                ))}
                {dayAppointments.length > MAX_VISIBLE && (
                  <span className="px-1 text-[10px] text-muted-foreground">
                    {`+${dayAppointments.length - MAX_VISIBLE} autre${
                      dayAppointments.length - MAX_VISIBLE > 1 ? 's' : ''
                    }`}
                  </span>
                )}
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
