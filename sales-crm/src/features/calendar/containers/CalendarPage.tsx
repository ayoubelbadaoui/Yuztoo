import { CalendarToolbar } from '@/features/calendar/components/CalendarToolbar'
import { DayAgenda } from '@/features/calendar/components/DayAgenda'
import { MonthGrid } from '@/features/calendar/components/MonthGrid'
import { WeekGrid } from '@/features/calendar/components/WeekGrid'
import { useCalendar } from '@/features/calendar/hooks/useCalendar'

export function CalendarPage() {
  const {
    view,
    setView,
    anchor,
    days,
    appointments,
    selectedDay,
    setSelectedDay,
    isLoading,
    error,
    shift,
    goToToday,
  } = useCalendar()

  if (error) {
    return (
      <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-[13px] text-destructive">
        Impossible de charger l’agenda.
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col gap-4">
      <header className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          Calendrier
        </h1>
        <p className="text-[13px] text-muted-foreground">
          Rendez-vous et relances rattachés aux leads.
        </p>
      </header>

      <CalendarToolbar
        anchor={anchor}
        view={view}
        count={appointments.length}
        onView={setView}
        onShift={shift}
        onToday={goToToday}
      />

      {isLoading ? (
        <div className="h-96 animate-pulse rounded-xl bg-muted" />
      ) : (
        <div className="flex min-h-0 flex-1 flex-col gap-4 xl:flex-row">
          {view === 'month' ? (
            <MonthGrid
              days={days}
              anchor={anchor}
              appointments={appointments}
              selectedDay={selectedDay}
              onSelect={setSelectedDay}
            />
          ) : (
            <WeekGrid
              days={days}
              appointments={appointments}
              selectedDay={selectedDay}
              onSelect={setSelectedDay}
            />
          )}

          <DayAgenda day={selectedDay} appointments={appointments} />
        </div>
      )}
    </div>
  )
}
