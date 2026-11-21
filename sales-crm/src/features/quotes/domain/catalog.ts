export type PlanId = 'essentielle' | 'premium'
export type ModuleId = 'boutique' | 'reservation' | 'ecoaching'

export type Plan = {
  id: PlanId
  name: string
  /** Abonnement de base, en euros par mois. */
  monthlyPrice: number
  /** Modules à la carte compris dans la formule. */
  includedModules: number
  extraModulePrice: number
  /** Plaques ou porte-clés NFC compris, facturés une seule fois au-delà. */
  includedNfc: number
  extraNfcPrice: number
  highlights: string[]
}

export const plans: Record<PlanId, Plan> = {
  essentielle: {
    id: 'essentielle',
    name: 'Essentielle',
    monthlyPrice: 29,
    includedModules: 0,
    extraModulePrice: 15,
    includedNfc: 1,
    extraNfcPrice: 15,
    highlights: [
      '300 clients connectés',
      '300 notifications / mois',
      '1 lien utile, galerie photos',
      'Découverte incluse 3 mois',
    ],
  },
  premium: {
    id: 'premium',
    name: 'Premium',
    monthlyPrice: 49,
    includedModules: 1,
    extraModulePrice: 10,
    includedNfc: 3,
    extraNfcPrice: 10,
    highlights: [
      'Clients et notifications illimités',
      'Liens illimités, photos et vidéo',
      'Parrainage et avis Google',
      'Découverte incluse en continu',
    ],
  },
}

export const planOrder: PlanId[] = ['essentielle', 'premium']

export const modules: Record<ModuleId, { id: ModuleId; name: string }> = {
  boutique: { id: 'boutique', name: 'Boutique en ligne' },
  reservation: { id: 'reservation', name: 'Réservation en ligne' },
  ecoaching: { id: 'ecoaching', name: 'E-Coaching' },
}

export const moduleOrder: ModuleId[] = ['boutique', 'reservation', 'ecoaching']

/** Durées d'engagement proposées, avec la remise d'usage associée. */
export const engagements = [
  { months: 1, label: 'Mensuel', suggestedDiscount: 0, suggestedFreeMonths: 0 },
  { months: 12, label: '12 mois', suggestedDiscount: 10, suggestedFreeMonths: 1 },
  { months: 24, label: '24 mois', suggestedDiscount: 15, suggestedFreeMonths: 2 },
] as const

export type EngagementMonths = (typeof engagements)[number]['months']

export { formatEuro } from '@/lib/money'
