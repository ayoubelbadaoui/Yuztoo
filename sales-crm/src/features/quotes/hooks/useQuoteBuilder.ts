import { useEffect, useMemo, useState } from 'react'

import type { Lead } from '@/features/leads/domain/lead'
import {
  getLeadById,
  searchLeads,
} from '@/features/leads/services/leadService'
import type {
  EngagementMonths,
  ModuleId,
  PlanId,
} from '@/features/quotes/domain/catalog'
import { engagements, plans } from '@/features/quotes/domain/catalog'
import { computeTotals } from '@/features/quotes/domain/pricing'
import type { Quote, QuoteStatus } from '@/features/quotes/domain/quote'
import { createQuote, updateQuote } from '@/features/quotes/services/quoteService'

export type QuoteFormValues = {
  leadId: string
  planId: PlanId
  moduleIds: ModuleId[]
  nfcQuantity: number
  engagementMonths: EngagementMonths
  freeMonths: number
  discountPercent: number
  status: QuoteStatus
}

const emptyForm: QuoteFormValues = {
  leadId: '',
  planId: 'premium',
  moduleIds: [],
  nfcQuantity: plans.premium.includedNfc,
  engagementMonths: 12,
  freeMonths: 1,
  discountPercent: 10,
  status: 'draft',
}

function toForm(quote: Quote): QuoteFormValues {
  return {
    leadId: quote.leadId,
    planId: quote.planId,
    moduleIds: quote.moduleIds,
    nfcQuantity: quote.nfcQuantity,
    engagementMonths: quote.engagementMonths,
    freeMonths: quote.freeMonths,
    discountPercent: quote.discountPercent,
    status: quote.status,
  }
}

export function useQuoteBuilder(quote: Quote | null, onSaved: () => void) {
  const [values, setValues] = useState<QuoteFormValues>(() =>
    quote ? toForm(quote) : emptyForm,
  )
  const [leads, setLeads] = useState<Lead[]>([])
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      const { data } = await searchLeads('', 50)
      const list = data ?? []
      const selectedId = quote?.leadId
      if (selectedId && !list.some((lead) => lead.id === selectedId)) {
        const { data: selected } = await getLeadById(selectedId)
        if (selected) list.unshift(selected)
      }
      setLeads(list)
    })()
  }, [quote?.leadId])

  const totals = useMemo(() => computeTotals(values), [values])

  const setField = <K extends keyof QuoteFormValues>(
    key: K,
    value: QuoteFormValues[K],
  ) => {
    setValues((current) => ({ ...current, [key]: value }))
    setError(null)
  }

  const toggleModule = (id: ModuleId) => {
    setValues((current) => ({
      ...current,
      moduleIds: current.moduleIds.includes(id)
        ? current.moduleIds.filter((moduleId) => moduleId !== id)
        : [...current.moduleIds, id],
    }))
  }

  /** Changer de formule réaligne le NFC sur ce que la formule comprend. */
  const setPlan = (planId: PlanId) => {
    setValues((current) => ({
      ...current,
      planId,
      nfcQuantity: Math.max(current.nfcQuantity, plans[planId].includedNfc),
    }))
  }

  /** La durée propose la remise et les mois offerts d'usage, modifiables ensuite. */
  const setEngagement = (months: EngagementMonths) => {
    const preset = engagements.find((option) => option.months === months)
    setValues((current) => ({
      ...current,
      engagementMonths: months,
      freeMonths: preset?.suggestedFreeMonths ?? 0,
      discountPercent: preset?.suggestedDiscount ?? 0,
    }))
  }

  const submit = async () => {
    const lead = leads.find((candidate) => candidate.id === values.leadId)
    if (!lead) {
      setError('Choisissez un lead.')
      return
    }

    setIsSaving(true)
    const draft = {
      ...values,
      leadName: lead.name,
      company: lead.company,
      owner: lead.owner === 'Non assigné' ? 'Sara M.' : lead.owner,
    }
    const { error: failure } = quote
      ? await updateQuote(quote.id, draft)
      : await createQuote(draft)
    setIsSaving(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onSaved()
  }

  return {
    values,
    leads,
    totals,
    setField,
    setPlan,
    setEngagement,
    toggleModule,
    isSaving,
    error,
    submit,
  }
}
