import { Clock, MapPin, User } from 'lucide-react'

import type { Appointment } from '@/features/calendar/domain/appointment'
import {
  appointmentKindLabels,
  endOf,
  formatDayLabel,
  formatTime,
  isSameDay,
} from '@/features/calendar/domain/appointment'
import { Badge } from '@/components/ui/Badge'

type Props = {
  day: Date
  appointments: Appointment[]
}

export function DayAgenda({ day, appointments }: Props) {
  const dayAppointments = appointments.filter((appointment) =>
    isSameDay(new Date(appointment.start), day),
  )

  return (
    <aside className="flex max-h-[26rem] shrink-0 flex-col gap-3 rounded-xl border border-border bg-card p-3 xl:max-h-none xl:w-72">
      <header>
        <h2 className="text-[13px] font-semibold text-card-foreground">
          {formatDayLabel(day)}
        </h2>
        <p className="text-[12px] text-muted-foreground">
          {dayAppointments.length === 0
            ? 'Aucun rendez-vous'
            : `${dayAppointments.length} rendez-vous`}
        </p>
      </header>

      <ol className="scrollbar-none flex min-h-0 flex-col gap-2 overflow-y-auto">
        {dayAppointments.map((appointment) => (
          <li
            key={appointment.id}
            className="rounded-lg border border-border p-2.5"
          >
            <div className="flex items-start justify-between gap-2">
              <p className="text-[13px] font-medium leading-tight text-card-foreground">
                {appointment.leadName}
              </p>
              <Badge tone="primary">
                {appointmentKindLabels[appointment.kind]}
              </Badge>
            </div>

            <p className="mt-0.5 text-[12px] text-muted-foreground">
              {appointment.title}
            </p>

            <dl className="mt-2 flex flex-col gap-1 text-[11px] text-muted-foreground">
              <div className="flex items-center gap-1.5">
                <Clock className="size-3" />
                <dd className="tabular-nums">
                  {`${formatTime(appointment.start)} – ${formatTime(
                    endOf(appointment).toISOString(),
                  )}`}
                </dd>
              </div>
              {appointment.location && (
                <div className="flex items-center gap-1.5">
                  <MapPin className="size-3" />
                  <dd>{appointment.location}</dd>
                </div>
              )}
              <div className="flex items-center gap-1.5">
                <User className="size-3" />
                <dd>{appointment.owner}</dd>
              </div>
            </dl>
          </li>
        ))}
      </ol>
    </aside>
  )
}
