import { mockLeads } from '@/features/leads/services/leadData'
import type { ModuleId, PlanId } from '@/features/quotes/domain/catalog'
import type { Quote, QuoteStatus } from '@/features/quotes/domain/quote'
import { loadOrSeed, persist } from '@/lib/mockStore'

type Row = [
  leadIndex: number,
  planId: PlanId,
  moduleIds: ModuleId[],
  nfcQuantity: number,
  engagementMonths: 1 | 12 | 24,
  freeMonths: number,
  discountPercent: number,
  status: QuoteStatus,
  daysAgo: number,
]

const rows: Row[] = [
  [0, 'premium', ['boutique'], 3, 12, 1, 10, 'sent', 1],
  [8, 'premium', ['boutique', 'reservation'], 5, 24, 2, 15, 'sent', 3],
  [21, 'premium', ['reservation'], 3, 12, 1, 10, 'accepted', 4],
  [12, 'essentielle', ['ecoaching'], 2, 12, 1, 10, 'sent', 5],
  [15, 'premium', ['boutique'], 4, 12, 0, 5, 'draft', 0],
  [7, 'essentielle', [], 1, 1, 0, 0, 'accepted', 6],
  [4, 'premium', ['boutique', 'ecoaching'], 3, 24, 2, 15, 'accepted', 8],
  [19, 'essentielle', ['boutique'], 1, 12, 1, 10, 'refused', 9],
  [2, 'essentielle', [], 2, 1, 0, 0, 'draft', 2],
  [11, 'premium', ['reservation', 'ecoaching'], 6, 24, 2, 15, 'sent', 7],
]

function isoDaysAgo(days: number): string {
  return new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString()
}

function seedQuotes(): Quote[] {
  return rows.map(
    (
      [
        leadIndex,
        planId,
        moduleIds,
        nfcQuantity,
        engagementMonths,
        freeMonths,
        discountPercent,
        status,
        daysAgo,
      ],
      index,
    ) => {
      const lead = mockLeads[leadIndex]
      return {
        id: `DV-${320 - index}`,
        leadId: lead.id,
        leadName: lead.name,
        company: lead.company,
        planId,
        moduleIds,
        nfcQuantity,
        engagementMonths,
        freeMonths,
        discountPercent,
        status,
        owner: lead.owner === 'Non assigné' ? 'Sara M.' : lead.owner,
        createdAt: isoDaysAgo(daysAgo + 2),
        updatedAt: isoDaysAgo(daysAgo),
      }
    },
  )
}

/** Jeu de démonstration, remplacé par Supabase sans toucher aux appelants. */
export const mockQuotes: Quote[] = loadOrSeed('quotes', seedQuotes)

/** À appeler après toute écriture, pour qu'un lien partagé survive au rechargement. */
export function saveQuotes(): void {
  persist('quotes', mockQuotes)
}
