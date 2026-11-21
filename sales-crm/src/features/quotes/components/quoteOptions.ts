import type { ComboboxOption } from '@/components/ui/Combobox'
import { plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'
import type { Quote } from '@/features/quotes/domain/quote'
import { formatEuro } from '@/lib/money'

/**
 * Devis présentés par client plutôt que par numéro : c'est le nom du commerçant
 * que le commercial a en tête quand il ouvre le sélecteur.
 */
export function quoteOptions(quotes: Quote[]): ComboboxOption[] {
  return quotes.map((quote) => {
    const company = quote.company === '—' ? '' : `${quote.company} · `
    const monthly = formatEuro(computeTotals(quote).monthlyTotal)
    return {
      id: quote.id,
      label: quote.leadName,
      hint: `${company}${plans[quote.planId].name} · ${monthly}/mois · ${quote.id}`,
      keywords: `${quote.leadName} ${quote.company} ${quote.id} ${plans[quote.planId].name}`,
    }
  })
}
