export type SubscriptionStatus = 'active' | 'trial' | 'suspended' | 'cancelled'
export type PaymentMethod = 'sepa' | 'card' | 'transfer'

export type Subscription = {
  id: string
  quoteId: string | null
  leadId: string
  leadName: string
  company: string
  /** Nom de la formule figé à la signature, le tarif pouvant évoluer ensuite. */
  planName: string
  monthlyAmount: number
  engagementMonths: number
  /** Jour du mois où le prélèvement est présenté. */
  billingDay: number
  startDate: string
  status: SubscriptionStatus
  paymentMethod: PaymentMethod
  owner: string
}

export const subscriptionStatusLabels: Record<SubscriptionStatus, string> = {
  active: 'Actif',
  trial: 'Période offerte',
  suspended: 'Suspendu',
  cancelled: 'Résilié',
}

export const paymentMethodLabels: Record<PaymentMethod, string> = {
  sepa: 'Prélèvement SEPA',
  card: 'Carte bancaire',
  transfer: 'Virement',
}

/** Cycle de vie autorisé. Une résiliation est définitive côté CRM. */
export const statusTransitions: Record<
  SubscriptionStatus,
  SubscriptionStatus[]
> = {
  trial: ['active', 'suspended', 'cancelled'],
  active: ['suspended', 'cancelled'],
  suspended: ['active', 'cancelled'],
  cancelled: [],
}

export function transitionLabel(
  from: SubscriptionStatus,
  to: SubscriptionStatus,
): string {
  if (to === 'active') {
    return from === 'suspended' ? 'Reprendre' : 'Activer'
  }
  if (to === 'suspended') return 'Suspendre'
  if (to === 'cancelled') return 'Résilier'
  return 'Passer en période offerte'
}

/** Seul un abonnement vivant est prélevé. */
export function isBilling(status: SubscriptionStatus): boolean {
  return status === 'active' || status === 'trial'
}

/** Fin d'engagement, utile pour les relances de renouvellement. */
export function engagementEnd(subscription: Subscription): Date {
  const end = new Date(subscription.startDate)
  end.setMonth(end.getMonth() + subscription.engagementMonths)
  return end
}

export function formatDay(iso: string): string {
  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(iso))
}

export function formatMonth(iso: string): string {
  const label = new Intl.DateTimeFormat('fr-FR', {
    month: 'long',
    year: 'numeric',
  }).format(new Date(iso))
  return label.charAt(0).toUpperCase() + label.slice(1)
}
