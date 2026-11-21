import type {
  EngagementMonths,
  ModuleId,
  PlanId,
} from '@/features/quotes/domain/catalog'

export type QuoteStatus = 'draft' | 'sent' | 'accepted' | 'refused'

export const quoteStatusLabels: Record<QuoteStatus, string> = {
  draft: 'Brouillon',
  sent: 'Envoyé',
  accepted: 'Accepté',
  refused: 'Refusé',
}

export type Quote = {
  id: string
  leadId: string
  leadName: string
  company: string
  planId: PlanId
  moduleIds: ModuleId[]
  /** Plaques et porte-clés NFC commandés, inclus compris. */
  nfcQuantity: number
  engagementMonths: EngagementMonths
  /** Mois offerts sur la durée d'engagement. */
  freeMonths: number
  discountPercent: number
  status: QuoteStatus
  owner: string
  createdAt: string
  updatedAt: string
}

export function formatQuoteDate(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(iso))
}
