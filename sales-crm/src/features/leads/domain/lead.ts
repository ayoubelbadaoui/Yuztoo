export type LeadType = 'merchant' | 'client'

export type LeadStage =
  | 'new'
  | 'contacted'
  | 'qualified'
  | 'negotiation'
  | 'won'
  | 'lost'

export type StorefrontStatus = 'online' | 'offline'

export type Lead = {
  id: string
  name: string
  company: string
  city: string
  type: LeadType
  stage: LeadStage
  amount: number
  owner: string
  updatedAt: string
  /** Instagram handle without @ — null when the source had no IG. */
  instagram: string | null
  email: string | null
  phone: string | null
  /** Métier / catégorie prospection. */
  trade: string | null
  /** Priorité commerciale 1–4. */
  priority: 1 | 2 | 3 | 4 | null
  /** Déjà une vitrine Yuztoo. */
  yuztooStorefront: boolean | null
  storefrontStatus: StorefrontStatus | null
}

export const leadTypeLabels: Record<LeadType, string> = {
  merchant: 'Commerçant',
  client: 'Client',
}

export const leadStageLabels: Record<LeadStage, string> = {
  new: 'Nouveau',
  contacted: 'Contacté',
  qualified: 'Qualifié',
  negotiation: 'Négociation',
  won: 'Gagné',
  lost: 'Perdu',
}

export const priorityLabels: Record<1 | 2 | 3 | 4, string> = {
  1: 'Priorité 1',
  2: 'Priorité 2',
  3: 'Priorité 3',
  4: 'Priorité 4',
}

/** Sales reps available for assignment, until the team table exists. */
export const leadOwners = [
  'Non assigné',
  'Sara M.',
  'Ayoub T.',
  'Yasmine K.',
] as const

/** Ordered stages, used by the pipeline board and the funnel summary. */
export const leadStageOrder: LeadStage[] = [
  'new',
  'contacted',
  'qualified',
  'negotiation',
  'won',
]

/**
 * Default page size for lead tables. Never render unbounded lists in the CRM
 * shell — 25 keeps the DOM light at 300 or 4 000 rows; the service still
 * returns `total` for the pager.
 */
export const LEAD_PAGE_SIZE = 25

export const LEAD_PAGE_SIZE_OPTIONS = [25, 50, 100] as const

export function instagramUrl(handle: string): string {
  const clean = handle.replace(/^@/, '').trim()
  return `https://www.instagram.com/${encodeURIComponent(clean)}/`
}

export function formatAmount(amount: number): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 0,
  }).format(amount)
}

export function formatRelativeDate(iso: string): string {
  const days = Math.round(
    (Date.now() - new Date(iso).getTime()) / (1000 * 60 * 60 * 24),
  )
  if (days <= 0) return "aujourd'hui"
  if (days === 1) return 'hier'
  return `il y a ${days} jours`
}
