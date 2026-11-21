import { useCallback, useEffect, useMemo, useState } from 'react'

import type { Appointment } from '@/features/calendar/domain/appointment'
import {
  addDays,
  monthGridDays,
  startOfDay,
  startOfWeek,
} from '@/features/calendar/domain/appointment'
import { getAppointmentsBetween } from '@/features/calendar/services/appointmentService'

export type CalendarView = 'month' | 'week'

export function useCalendar() {
  const [view, setView] = useState<CalendarView>('month')
  const [anchor, setAnchor] = useState(() => startOfDay(new Date()))
  const [selectedDay, setSelectedDay] = useState(() => startOfDay(new Date()))
  const [appointments, setAppointments] = useState<Appointment[]>([])
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const days = useMemo(
    () =>
      view === 'month'
        ? monthGridDays(anchor)
        : Array.from({ length: 7 }, (_, index) =>
            addDays(startOfWeek(anchor), index),
          ),
    [anchor, view],
  )

  useEffect(() => {
    let active = true
    const from = days[0]
    const to = addDays(days[days.length - 1], 1)

    setIsLoading(true)
    void getAppointmentsBetween(from, to).then(({ data, error: failure }) => {
      if (!active) return
      if (failure || !data) {
        setError(failure ?? new Error('Agenda indisponible'))
      } else {
        setError(null)
        setAppointments(data)
      }
      setIsLoading(false)
    })

    return () => {
      active = false
    }
  }, [days])

  const shift = useCallback(
    (direction: -1 | 1) => {
      setAnchor((current) => {
        if (view === 'week') return addDays(current, direction * 7)
        return new Date(current.getFullYear(), current.getMonth() + direction, 1)
      })
    },
    [view],
  )

  const goToToday = useCallback(() => {
    const today = startOfDay(new Date())
    setAnchor(today)
    setSelectedDay(today)
  }, [])

  return {
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
  }
}
