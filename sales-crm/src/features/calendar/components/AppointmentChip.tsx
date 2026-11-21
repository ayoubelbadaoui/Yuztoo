import type {
  Appointment,
  AppointmentKind,
} from '@/features/calendar/domain/appointment'
import { formatTime } from '@/features/calendar/domain/appointment'

const kindClasses: Record<AppointmentKind, string> = {
  call: 'border-l-muted-foreground/60',
  meeting: 'border-l-primary',
  demo: 'border-l-success',
  followup: 'border-l-warning',
}

type Props = {
  appointment: Appointment
  compact?: boolean
}

export function AppointmentChip({ appointment, compact = false }: Props) {
  return (
    <div
      className={`overflow-hidden rounded-[4px] border-l-2 bg-muted px-1.5 py-1 text-left ${
        kindClasses[appointment.kind]
      }`}
    >
      <p className="flex gap-1 text-[11px] leading-tight">
        <span className="shrink-0 tabular-nums text-muted-foreground">
          {formatTime(appointment.start)}
        </span>
        <span className="truncate font-medium text-foreground">
          {appointment.leadName}
        </span>
      </p>
      {!compact && (
        <p className="truncate text-[10px] text-muted-foreground">
          {appointment.title}
        </p>
      )}
    </div>
  )
}
