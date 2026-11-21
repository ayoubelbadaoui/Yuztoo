import type { Invoice } from '@/features/billing/domain/invoice'
import { daysLate, isOutstanding } from '@/features/billing/domain/invoice'
import type {
  PaymentMethod,
  Subscription,
  SubscriptionStatus,
} from '@/features/billing/domain/subscription'
import {
  formatMonth,
  isBilling,
  statusTransitions,
} from '@/features/billing/domain/subscription'
import {
  mockInvoices,
  mockSubscriptions,
} from '@/features/billing/services/billingData'
import { plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'
import type { Quote } from '@/features/quotes/domain/quote'
import { getQuotes } from '@/features/quotes/services/quoteService'

type Result<T> = { data: T | null; error: Error | null }

export type BillingSummary = {
  /** Revenu récurrent mensuel des abonnements actifs. */
  mrr: number
  activeCount: number
  outstandingAmount: number
  outstandingCount: number
  /** Part des échéances échues qui ont été encaissées. */
  collectionRate: number
}

export async function getSubscriptions(
  status: SubscriptionStatus | 'all' = 'all',
): Promise<Result<Subscription[]>> {
  try {
    const data = mockSubscriptions
      .filter((item) => status === 'all' || item.status === status)
      .sort((a, b) => b.monthlyAmount - a.monthlyAmount)
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getBillingSummary(): Promise<Result<BillingSummary>> {
  try {
    const billable = mockSubscriptions.filter(
      (item) => item.status === 'active' || item.status === 'trial',
    )
    const outstanding = mockInvoices.filter(isOutstanding)
    const settled = mockInvoices.filter(
      (invoice) => invoice.status === 'paid' || isOutstanding(invoice),
    )
    const paid = settled.filter((invoice) => invoice.status === 'paid')

    return {
      data: {
        mrr: billable.reduce((sum, item) => sum + item.monthlyAmount, 0),
        activeCount: billable.length,
        outstandingAmount: outstanding.reduce(
          (sum, invoice) => sum + invoice.amount,
          0,
        ),
        outstandingCount: outstanding.length,
        collectionRate:
          settled.length === 0
            ? 100
            : Math.round((paid.length / settled.length) * 100),
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** File de recouvrement, du retard le plus ancien au plus récent. */
export async function getOutstandingInvoices(): Promise<Result<Invoice[]>> {
  try {
    const data = mockInvoices
      .filter(isOutstanding)
      .sort((a, b) => daysLate(b) - daysLate(a))
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getUpcomingInvoices(
  monthsAhead = 3,
): Promise<Result<Invoice[]>> {
  try {
    const from = new Date()
    from.setHours(0, 0, 0, 0)
    const to = new Date(from)
    to.setMonth(to.getMonth() + monthsAhead)

    const data = mockInvoices
      .filter((invoice) => {
        const due = new Date(invoice.dueDate)
        return due >= from && due <= to
      })
      .sort((a, b) => a.dueDate.localeCompare(b.dueDate))
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export type SubscriptionPatch = Partial<
  Pick<
    Subscription,
    'monthlyAmount' | 'billingDay' | 'paymentMethod' | 'engagementMonths' | 'owner'
  >
>

function find(id: string): Subscription {
  const subscription = mockSubscriptions.find(
    (candidate) => candidate.id === id,
  )
  if (!subscription) throw new Error(`Abonnement ${id} introuvable`)
  return subscription
}

/**
 * Réaligne les échéances à venir sur l'état courant de l'abonnement : on retire
 * celles qui n'ont pas encore été présentées, puis on les regénère si
 * l'abonnement est toujours prélevé. Les échéances passées ne bougent jamais.
 */
function syncScheduledInvoices(subscription: Subscription) {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  for (let index = mockInvoices.length - 1; index >= 0; index -= 1) {
    const invoice = mockInvoices[index]
    if (
      invoice.subscriptionId === subscription.id &&
      invoice.status === 'scheduled'
    ) {
      mockInvoices.splice(index, 1)
    }
  }

  if (!isBilling(subscription.status)) return

  const horizon = new Date(today)
  horizon.setMonth(horizon.getMonth() + 3)

  const cursor = new Date(today)
  cursor.setDate(subscription.billingDay)
  if (cursor <= today) cursor.setMonth(cursor.getMonth() + 1)

  let position = 1
  while (cursor <= horizon) {
    mockInvoices.push({
      id: `FA-${subscription.id.slice(3)}-N${position}`,
      subscriptionId: subscription.id,
      leadName: subscription.leadName,
      company: subscription.company,
      periodLabel: formatMonth(cursor.toISOString()),
      dueDate: cursor.toISOString(),
      amount: subscription.monthlyAmount,
      status: 'scheduled',
      paidAt: null,
      attempts: 0,
    })
    cursor.setMonth(cursor.getMonth() + 1)
    position += 1
  }

  mockInvoices.sort((a, b) => a.dueDate.localeCompare(b.dueDate))
}

export async function updateSubscription(
  id: string,
  patch: SubscriptionPatch,
): Promise<Result<Subscription>> {
  try {
    const subscription = find(id)
    if (patch.monthlyAmount !== undefined && patch.monthlyAmount < 0) {
      throw new Error('Le montant mensuel ne peut pas être négatif')
    }
    if (
      patch.billingDay !== undefined &&
      (patch.billingDay < 1 || patch.billingDay > 28)
    ) {
      throw new Error('Le jour de prélèvement doit être compris entre 1 et 28')
    }

    Object.assign(subscription, patch)
    syncScheduledInvoices(subscription)
    return { data: { ...subscription }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function setSubscriptionStatus(
  id: string,
  status: SubscriptionStatus,
): Promise<Result<Subscription>> {
  try {
    const subscription = find(id)
    if (!statusTransitions[subscription.status].includes(status)) {
      throw new Error(
        `Transition ${subscription.status} → ${status} non autorisée`,
      )
    }

    subscription.status = status
    syncScheduledInvoices(subscription)
    return { data: { ...subscription }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/**
 * Devis acceptés qui n'ont pas encore donné lieu à un abonnement.
 * La facturation dépend du devis, jamais l'inverse.
 */
export async function getStartableQuotes(): Promise<Result<Quote[]>> {
  try {
    const { data, error } = await getQuotes('accepted')
    if (error || !data) throw error ?? new Error('Devis indisponibles')

    const started = new Set(
      mockSubscriptions
        .map((subscription) => subscription.quoteId)
        .filter(Boolean),
    )
    return {
      data: data.filter((quote) => !started.has(quote.id)),
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function startSubscriptionFromQuote(
  quoteId: string,
  options: { billingDay: number; paymentMethod: PaymentMethod },
): Promise<Result<Subscription>> {
  try {
    const { data: startable } = await getStartableQuotes()
    const quote = startable?.find((candidate) => candidate.id === quoteId)
    if (!quote) throw new Error('Ce devis a déjà un abonnement')
    if (options.billingDay < 1 || options.billingDay > 28) {
      throw new Error('Le jour de prélèvement doit être compris entre 1 et 28')
    }

    const subscription: Subscription = {
      id: `AB-${1200 + mockSubscriptions.length}`,
      quoteId: quote.id,
      leadId: quote.leadId,
      leadName: quote.leadName,
      company: quote.company,
      planName: plans[quote.planId].name,
      monthlyAmount: computeTotals(quote).monthlyTotal,
      engagementMonths: quote.engagementMonths,
      billingDay: options.billingDay,
      startDate: new Date().toISOString(),
      status: quote.freeMonths > 0 ? 'trial' : 'active',
      paymentMethod: options.paymentMethod,
      owner: quote.owner,
    }

    mockSubscriptions.push(subscription)
    syncScheduledInvoices(subscription)
    return { data: subscription, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function markInvoicePaid(id: string): Promise<Result<Invoice>> {
  try {
    const invoice = mockInvoices.find((candidate) => candidate.id === id)
    if (!invoice) throw new Error(`Échéance ${id} introuvable`)

    invoice.status = 'paid'
    invoice.paidAt = new Date().toISOString()
    return { data: { ...invoice }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

/** Représente le prélèvement : la banque tranchera, on compte la tentative. */
export async function retryPayment(id: string): Promise<Result<Invoice>> {
  try {
    const invoice = mockInvoices.find((candidate) => candidate.id === id)
    if (!invoice) throw new Error(`Échéance ${id} introuvable`)

    invoice.attempts += 1
    invoice.status = 'late'
    return { data: { ...invoice }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
