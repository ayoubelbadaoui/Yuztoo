import { ChevronLeft, ChevronRight } from 'lucide-react'

import {
  addDays,
  formatMonthLabel,
  startOfWeek,
} from '@/features/calendar/domain/appointment'
import type { CalendarView } from '@/features/calendar/hooks/useCalendar'

type Props = {
  anchor: Date
  view: CalendarView
  count: number
  onView: (view: CalendarView) => void
  onShift: (direction: -1 | 1) => void
  onToday: () => void
}

function weekLabel(anchor: Date): string {
  const start = startOfWeek(anchor)
  const end = addDays(start, 6)
  const format = new Intl.DateTimeFormat('fr-FR', {
    day: 'numeric',
    month: 'short',
  })
  return `${format.format(start)} – ${format.format(end)}`
}

export function CalendarToolbar({
  anchor,
  view,
  count,
  onView,
  onShift,
  onToday,
}: Props) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div className="flex items-center gap-2">
        <div className="flex items-center rounded-lg border border-border">
          <button
            type="button"
            onClick={() => onShift(-1)}
            aria-label="Période précédente"
            className="flex size-8 items-center justify-center rounded-l-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          >
            <ChevronLeft className="size-4" />
          </button>
          <button
            type="button"
            onClick={() => onShift(1)}
            aria-label="Période suivante"
            className="flex size-8 items-center justify-center rounded-r-lg border-l border-border text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          >
            <ChevronRight className="size-4" />
          </button>
        </div>

        <button
          type="button"
          onClick={onToday}
          className="h-8 rounded-lg border border-border px-3 text-[13px] text-foreground transition-colors hover:bg-muted"
        >
          Aujourd’hui
        </button>

        <h2 className="pl-1 text-[15px] font-semibold text-foreground">
          {view === 'month' ? formatMonthLabel(anchor) : weekLabel(anchor)}
        </h2>
      </div>

      <div className="flex items-center gap-3">
        <span className="text-[12px] text-muted-foreground">
          {`${count} rendez-vous`}
        </span>
        <div className="flex rounded-lg border border-border p-0.5">
          {(['month', 'week'] as const).map((option) => (
            <button
              key={option}
              type="button"
              onClick={() => onView(option)}
              className={`h-7 rounded-[6px] px-3 text-[12px] transition-colors ${
                view === option
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {option === 'month' ? 'Mois' : 'Semaine'}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
