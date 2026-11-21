export type QualityRating = 'high' | 'medium' | 'low'

export const qualityLabels: Record<QualityRating, string> = {
  high: 'Qualité haute',
  medium: 'Qualité moyenne',
  low: 'Qualité basse',
}

/** Palier d'envoi Meta : nombre de conversations entamées par 24 h. */
export type MessagingTier = 250 | 1000 | 10_000 | 100_000

export type WaNumber = {
  id: string
  displayName: string
  phone: string
  verified: boolean
  quality: QualityRating
  tier: MessagingTier
  /** Conversations entamées sur les dernières 24 h, contre le palier. */
  used24h: number
}

export function tierLabel(tier: MessagingTier): string {
  return tier >= 100_000
    ? 'Illimité'
    : `${new Intl.NumberFormat('fr-FR').format(tier)} / 24 h`
}

export function usageRatio(number: WaNumber): number {
  return Math.min(1, number.used24h / number.tier)
}
