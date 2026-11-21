import { BadgeCheck, Check, MapPin, Moon, ShieldCheck, Sun } from 'lucide-react'
import { useEffect, useState } from 'react'

import { useTheme } from '@/lib/useTheme'
import { formatEuro, plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'
import type { Quote } from '@/features/quotes/domain/quote'
import { formatQuoteDate } from '@/features/quotes/domain/quote'
import { QuoteLineItems } from '@/features/quotes/components/QuoteLineItems'
import { getQuoteByShareToken } from '@/features/quotes/services/quoteService'

const trustPoints = [
  { icon: ShieldCheck, label: 'Aucune commission sur vos ventes' },
  { icon: BadgeCheck, label: 'Vos données vous appartiennent' },
  { icon: MapPin, label: 'Souveraineté locale' },
]

export function PublicQuotePage({ token }: { token: string }) {
  const { theme, toggleTheme } = useTheme()
  const [quote, setQuote] = useState<Quote | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isAccepted, setIsAccepted] = useState(false)

  useEffect(() => {
    void getQuoteByShareToken(token).then(({ data }) => {
      setQuote(data)
      setIsLoading(false)
    })
  }, [token])

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background p-6">
        <div className="mx-auto h-96 max-w-2xl animate-pulse rounded-2xl bg-muted" />
      </div>
    )
  }

  if (!quote) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background p-6">
        <div className="max-w-sm text-center">
          <h1 className="text-lg font-semibold text-foreground">
            Ce devis n’est plus disponible
          </h1>
          <p className="mt-1 text-[13px] text-muted-foreground">
            Le lien a peut-être expiré. Demandez-en un nouveau à votre
            conseiller Yuztoo.
          </p>
        </div>
      </div>
    )
  }

  const plan = plans[quote.planId]
  const totals = computeTotals(quote)

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-card">
        <div className="mx-auto flex max-w-2xl items-center justify-between gap-4 px-5 py-4">
          <div className="flex items-center gap-2.5">
            <span className="flex size-8 items-center justify-center rounded-lg bg-primary text-[15px] font-bold text-primary-foreground">
              Y
            </span>
            <div className="leading-tight">
              <p className="text-[15px] font-semibold text-card-foreground">
                yuztoo
              </p>
              <p className="text-[11px] italic text-muted-foreground">
                Le lien est la force.
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={toggleTheme}
            aria-label="Basculer le thème clair ou sombre"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            {theme === 'dark' ? (
              <Sun className="size-[18px]" strokeWidth={1.5} />
            ) : (
              <Moon className="size-[18px]" strokeWidth={1.5} />
            )}
          </button>
        </div>
      </header>

      <main className="mx-auto max-w-2xl px-5 py-8">
        <div className="flex flex-col gap-5">
          <div>
            <p className="text-[12px] uppercase tracking-wide text-primary">
              Proposition commerciale
            </p>
            <h1 className="mt-1 text-2xl font-semibold tracking-tight text-foreground">
              {quote.company === '—' ? quote.leadName : quote.company}
            </h1>
            <p className="mt-1 text-[13px] text-muted-foreground">
              {`Préparée pour ${quote.leadName} par ${quote.owner} · ${quote.id} · ${formatQuoteDate(quote.createdAt)}`}
            </p>
          </div>

          <section className="overflow-hidden rounded-2xl border border-border bg-card">
            <div className="flex flex-wrap items-baseline justify-between gap-2 border-b border-border bg-primary/5 px-5 py-4">
              <div>
                <p className="text-[12px] text-muted-foreground">
                  Formule retenue
                </p>
                <p className="text-[17px] font-semibold text-card-foreground">
                  {plan.name}
                </p>
              </div>
              <p className="text-[17px] font-semibold tabular-nums text-card-foreground">
                {formatEuro(totals.monthlyTotal)}
                <span className="text-[12px] font-normal text-muted-foreground">
                  {' '}
                  /mois
                </span>
              </p>
            </div>

            <ul className="grid gap-2 border-b border-border px-5 py-4 sm:grid-cols-2">
              {plan.highlights.map((highlight) => (
                <li
                  key={highlight}
                  className="flex items-start gap-2 text-[13px] text-card-foreground"
                >
                  <Check className="mt-0.5 size-3.5 shrink-0 text-primary" />
                  {highlight}
                </li>
              ))}
            </ul>

            <div className="px-5 py-1">
              <QuoteLineItems quote={quote} totals={totals} />
            </div>

            <div className="flex flex-wrap items-baseline justify-between gap-2 border-t border-border bg-muted/40 px-5 py-4">
              <div>
                <p className="text-[13px] font-semibold text-card-foreground">
                  Total de la proposition
                </p>
                <p className="text-[12px] text-muted-foreground">
                  {`Engagement ${quote.engagementMonths} mois, matériel compris`}
                </p>
              </div>
              <p className="text-2xl font-semibold tabular-nums text-card-foreground">
                {formatEuro(totals.grandTotal)}
              </p>
            </div>
          </section>

          {isAccepted ? (
            <div className="flex items-center gap-2 rounded-xl border border-success/30 bg-success/10 px-4 py-3 text-[13px] text-success">
              <Check className="size-4 shrink-0" />
              Merci, votre accord est transmis. Votre conseiller vous recontacte
              sous 24 h.
            </div>
          ) : (
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => setIsAccepted(true)}
                className="h-10 flex-1 rounded-lg bg-primary px-4 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90"
              >
                Accepter la proposition
              </button>
              <button
                type="button"
                className="h-10 flex-1 rounded-lg border border-border px-4 text-[13px] text-foreground transition-colors hover:bg-muted"
              >
                Poser une question
              </button>
            </div>
          )}

          <ul className="flex flex-wrap justify-center gap-x-5 gap-y-2 pt-2">
            {trustPoints.map(({ icon: Icon, label }) => (
              <li
                key={label}
                className="flex items-center gap-1.5 text-[11px] text-muted-foreground"
              >
                <Icon className="size-3.5 text-primary" />
                {label}
              </li>
            ))}
          </ul>
        </div>
      </main>
    </div>
  )
}
