import type {
  PaymentMethod,
  Subscription,
  SubscriptionStatus,
} from '@/features/billing/domain/subscription'
import { formatMonth } from '@/features/billing/domain/subscription'
import type { Invoice, InvoiceStatus } from '@/features/billing/domain/invoice'
import { mockLeads } from '@/features/leads/services/leadData'
import type { ModuleId, PlanId } from '@/features/quotes/domain/catalog'
import { plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'

type Row = [
  leadIndex: number,
  planId: PlanId,
  moduleIds: ModuleId[],
  discountPercent: number,
  engagementMonths: number,
  monthsAgo: number,
  billingDay: number,
  status: SubscriptionStatus,
  paymentMethod: PaymentMethod,
  /** Nombre d'échéances récentes impayées, pour alimenter le recouvrement. */
  unpaid: number,
]

const rows: Row[] = [
  [4, 'premium', ['boutique', 'ecoaching'], 15, 24, 14, 5, 'active', 'sepa', 0],
  [11, 'essentielle', ['boutique'], 10, 12, 9, 5, 'active', 'sepa', 0],
  [18, 'premium', ['reservation'], 10, 12, 7, 10, 'active', 'card', 1],
  [24, 'essentielle', [], 0, 12, 6, 15, 'active', 'transfer', 0],
  [0, 'premium', ['boutique'], 10, 24, 5, 5, 'active', 'sepa', 0],
  [1, 'essentielle', ['ecoaching'], 10, 12, 4, 10, 'active', 'sepa', 2],
  [7, 'premium', ['boutique', 'reservation'], 15, 24, 11, 5, 'active', 'sepa', 0],
  [8, 'premium', ['reservation'], 10, 12, 3, 20, 'active', 'card', 3],
  [12, 'premium', ['boutique'], 10, 12, 2, 5, 'active', 'sepa', 0],
  [21, 'essentielle', ['boutique'], 0, 12, 1, 10, 'trial', 'sepa', 0],
  [22, 'premium', ['boutique', 'ecoaching'], 15, 24, 8, 5, 'suspended', 'card', 4],
  [2, 'essentielle', [], 0, 12, 10, 25, 'cancelled', 'transfer', 0],
]

const DAY = 24 * 60 * 60 * 1000

function startOfToday(): Date {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  return today
}

function monthlyAmountFor(row: Row): number {
  const [, planId, moduleIds, discountPercent] = row
  return computeTotals({
    planId,
    moduleIds,
    nfcQuantity: plans[planId].includedNfc,
    engagementMonths: 1,
    freeMonths: 0,
    discountPercent,
  }).monthlyTotal
}

export const mockSubscriptions: Subscription[] = rows.map((row, index) => {
  const [
    leadIndex,
    planId,
    ,
    ,
    engagementMonths,
    monthsAgo,
    billingDay,
    status,
    paymentMethod,
  ] = row
  const lead = mockLeads[leadIndex]
  const start = startOfToday()
  start.setMonth(start.getMonth() - monthsAgo)
  start.setDate(billingDay)

  return {
    id: `AB-${1200 + index}`,
    quoteId: null,
    leadId: lead.id,
    leadName: lead.name,
    company: lead.company,
    planName: plans[planId].name,
    monthlyAmount: monthlyAmountFor(row),
    engagementMonths,
    billingDay,
    startDate: start.toISOString(),
    status,
    paymentMethod,
    owner: lead.owner === 'Non assigné' ? 'Sara M.' : lead.owner,
  }
})

/** Échéancier : une ligne par mois, du démarrage jusqu'à trois mois devant. */
function buildInvoices(): Invoice[] {
  const today = startOfToday()
  const invoices: Invoice[] = []

  mockSubscriptions.forEach((subscription, index) => {
    const unpaid = rows[index][9]
    const cursor = new Date(subscription.startDate)
    // Seul un abonnement vivant continue d'être prélevé.
    const isBilling =
      subscription.status === 'active' || subscription.status === 'trial'
    const horizon = new Date(today)
    if (isBilling) horizon.setMonth(horizon.getMonth() + 3)

    const dueDates: Date[] = []
    while (cursor <= horizon) {
      dueDates.push(new Date(cursor))
      cursor.setMonth(cursor.getMonth() + 1)
    }

    const settled = dueDates.filter(
      (date) => date.getTime() < today.getTime() - 2 * DAY,
    )
    const troubled = new Set(
      settled.slice(settled.length - unpaid).map((date) => date.getTime()),
    )

    dueDates.forEach((dueDate, position) => {
      const time = dueDate.getTime()
      let status: InvoiceStatus
      let attempts = 0

      if (troubled.has(time)) {
        const isOldest = time === Math.min(...troubled)
        status = isOldest && unpaid > 1 ? 'failed' : 'late'
        attempts = status === 'failed' ? 2 : 1
      } else if (time < today.getTime() - 2 * DAY) {
        status = 'paid'
        attempts = 1
      } else if (time <= today.getTime() + 7 * DAY) {
        status = 'due'
      } else {
        status = 'scheduled'
      }

      invoices.push({
        id: `FA-${subscription.id.slice(3)}-${String(position + 1).padStart(2, '0')}`,
        subscriptionId: subscription.id,
        leadName: subscription.leadName,
        company: subscription.company,
        periodLabel: formatMonth(dueDate.toISOString()),
        dueDate: dueDate.toISOString(),
        amount: subscription.monthlyAmount,
        status,
        paidAt: status === 'paid' ? dueDate.toISOString() : null,
        attempts,
      })
    })
  })

  return invoices.sort((a, b) => a.dueDate.localeCompare(b.dueDate))
}

export const mockInvoices: Invoice[] = buildInvoices()
