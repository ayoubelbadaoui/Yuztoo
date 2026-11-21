import type { ModuleId, PlanId } from '@/features/quotes/domain/catalog'
import { plans } from '@/features/quotes/domain/catalog'

export type PricingInput = {
  planId: PlanId
  moduleIds: ModuleId[]
  nfcQuantity: number
  engagementMonths: number
  freeMonths: number
  discountPercent: number
}

export type QuoteTotals = {
  planMonthly: number
  /** Modules facturés, une fois déduits ceux compris dans la formule. */
  billedModules: number
  modulesMonthly: number
  monthlySubtotal: number
  discountAmount: number
  monthlyTotal: number
  /** Matériel NFC au-delà du quota, facturé une seule fois. */
  billedNfc: number
  nfcOneOff: number
  billedMonths: number
  recurringTotal: number
  /** Montant du devis : abonnement sur la durée + matériel. */
  grandTotal: number
}

export function computeTotals(input: PricingInput): QuoteTotals {
  const plan = plans[input.planId]

  const billedModules = Math.max(
    0,
    input.moduleIds.length - plan.includedModules,
  )
  const modulesMonthly = billedModules * plan.extraModulePrice
  const monthlySubtotal = plan.monthlyPrice + modulesMonthly

  const discountAmount = (monthlySubtotal * input.discountPercent) / 100
  const monthlyTotal = monthlySubtotal - discountAmount

  const billedNfc = Math.max(0, input.nfcQuantity - plan.includedNfc)
  const nfcOneOff = billedNfc * plan.extraNfcPrice

  const billedMonths = Math.max(0, input.engagementMonths - input.freeMonths)
  const recurringTotal = monthlyTotal * billedMonths

  return {
    planMonthly: plan.monthlyPrice,
    billedModules,
    modulesMonthly,
    monthlySubtotal,
    discountAmount,
    monthlyTotal,
    billedNfc,
    nfcOneOff,
    billedMonths,
    recurringTotal,
    grandTotal: recurringTotal + nfcOneOff,
  }
}
