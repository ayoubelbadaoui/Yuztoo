import type { Quote, QuoteStatus } from '@/features/quotes/domain/quote'
import { computeTotals } from '@/features/quotes/domain/pricing'
import { shareTokenFor } from '@/features/quotes/domain/share'
import { mockQuotes, saveQuotes } from '@/features/quotes/services/quoteData'

type Result<T> = { data: T | null; error: Error | null }

export type QuoteDraft = Omit<
  Quote,
  'id' | 'createdAt' | 'updatedAt' | 'leadName' | 'company'
> & { leadName: string; company: string }

/** Reprend après le dernier identifiant connu, y compris restauré du cache. */
let sequence = mockQuotes.reduce(
  (max, quote) => Math.max(max, Number(quote.id.slice(3)) || 0),
  320,
)

function validate(draft: QuoteDraft) {
  if (!draft.leadId) throw new Error('Choisissez un lead')
  if (draft.nfcQuantity < 0) throw new Error('Quantité NFC invalide')
  if (draft.discountPercent < 0 || draft.discountPercent > 100) {
    throw new Error('La remise doit être comprise entre 0 et 100 %')
  }
  if (draft.freeMonths < 0 || draft.freeMonths > draft.engagementMonths) {
    throw new Error('Les mois offerts dépassent la durée d’engagement')
  }
}

export async function getQuotes(
  status: QuoteStatus | 'all' = 'all',
): Promise<Result<Quote[]>> {
  try {
    const data = mockQuotes
      .filter((quote) => status === 'all' || quote.status === status)
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getQuoteCounts(): Promise<
  Result<Record<QuoteStatus | 'all', number>>
> {
  try {
    return {
      data: {
        all: mockQuotes.length,
        draft: mockQuotes.filter((quote) => quote.status === 'draft').length,
        sent: mockQuotes.filter((quote) => quote.status === 'sent').length,
        accepted: mockQuotes.filter((quote) => quote.status === 'accepted')
          .length,
        refused: mockQuotes.filter((quote) => quote.status === 'refused')
          .length,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createQuote(draft: QuoteDraft): Promise<Result<Quote>> {
  try {
    validate(draft)
    const now = new Date().toISOString()
    const quote: Quote = {
      ...draft,
      id: `DV-${(sequence += 1)}`,
      createdAt: now,
      updatedAt: now,
    }
    mockQuotes.unshift(quote)
    saveQuotes()
    return { data: quote, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateQuote(
  id: string,
  draft: QuoteDraft,
): Promise<Result<Quote>> {
  try {
    validate(draft)
    const quote = mockQuotes.find((candidate) => candidate.id === id)
    if (!quote) throw new Error(`Devis ${id} introuvable`)

    Object.assign(quote, draft)
    quote.updatedAt = new Date().toISOString()
    saveQuotes()
    return { data: { ...quote }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getQuoteByShareToken(
  token: string,
): Promise<Result<Quote>> {
  try {
    const quote = mockQuotes.find(
      (candidate) => shareTokenFor(candidate.id) === token,
    )
    if (!quote) throw new Error('Devis introuvable')
    return { data: { ...quote }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Montant signé d'un devis, calculé à la volée depuis la grille tarifaire. */
export function quoteAmount(quote: Quote): number {
  return computeTotals(quote).grandTotal
}
