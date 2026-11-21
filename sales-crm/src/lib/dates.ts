/** Aides de date partagées par l'agenda et le calendrier éditorial. */

export const weekdayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

export function startOfDay(date: Date): Date {
  const copy = new Date(date)
  copy.setHours(0, 0, 0, 0)
  return copy
}

/** Semaine commençant le lundi, convention française. */
export function startOfWeek(date: Date): Date {
  const copy = startOfDay(date)
  const offset = (copy.getDay() + 6) % 7
  copy.setDate(copy.getDate() - offset)
  return copy
}

export function addDays(date: Date, days: number): Date {
  const copy = new Date(date)
  copy.setDate(copy.getDate() + days)
  return copy
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

/** Six semaines couvrant le mois, pour que la grille ne change jamais de hauteur. */
export function monthGridDays(reference: Date): Date[] {
  const first = startOfWeek(
    new Date(reference.getFullYear(), reference.getMonth(), 1),
  )
  return Array.from({ length: 42 }, (_, index) => addDays(first, index))
}

function capitalize(label: string): string {
  return label.charAt(0).toUpperCase() + label.slice(1)
}

export function formatMonthLabel(date: Date): string {
  return capitalize(
    new Intl.DateTimeFormat('fr-FR', {
      month: 'long',
      year: 'numeric',
    }).format(date),
  )
}

export function formatDayLabel(date: Date): string {
  return capitalize(
    new Intl.DateTimeFormat('fr-FR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
    }).format(date),
  )
}

export function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}
