import type { BadgeTone } from '@/components/ui/Badge'
import type { Invoice } from '@/features/billing/domain/invoice'
import { daysLate } from '@/features/billing/domain/invoice'

export type DunningLevel = 'watch' | 'reminder' | 'call' | 'formal' | 'suspension'

type Step = {
  level: DunningLevel
  /** Jours de retard à partir desquels l'étape s'applique. */
  fromDays: number
  label: string
  action: string
  tone: BadgeTone
}

/**
 * Échelle de recouvrement. Le commercial reste maître de la décision :
 * l'étape proposée est une recommandation, pas une action automatique.
 */
export const dunningSteps: Step[] = [
  {
    level: 'suspension',
    fromDays: 30,
    label: 'Suspension',
    action: 'Suspendre le service et transmettre au recouvrement',
    tone: 'danger',
  },
  {
    level: 'formal',
    fromDays: 15,
    label: 'Mise en demeure',
    action: 'Envoyer la mise en demeure avec accusé de réception',
    tone: 'danger',
  },
  {
    level: 'call',
    fromDays: 7,
    label: 'Appel',
    action: 'Appeler le commerçant pour débloquer le paiement',
    tone: 'warning',
  },
  {
    level: 'reminder',
    fromDays: 3,
    label: 'Relance',
    action: 'Relancer par e-mail avec le lien de paiement',
    tone: 'warning',
  },
  {
    level: 'watch',
    fromDays: 0,
    label: 'À surveiller',
    action: 'Laisser la banque représenter le prélèvement',
    tone: 'neutral',
  },
]

export function dunningStepFor(invoice: Invoice, now = new Date()): Step {
  const late = daysLate(invoice, now)
  return (
    dunningSteps.find((step) => late >= step.fromDays) ??
    dunningSteps[dunningSteps.length - 1]
  )
}
