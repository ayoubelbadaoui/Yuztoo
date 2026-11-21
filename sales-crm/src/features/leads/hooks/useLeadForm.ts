import { useMemo, useState } from 'react'

import type { Lead, LeadStage, LeadType } from '@/features/leads/domain/lead'
import { updateLead } from '@/features/leads/services/leadService'

export type LeadFormValues = {
  name: string
  company: string
  city: string
  type: LeadType
  stage: LeadStage
  amount: string
  owner: string
}

function toForm(lead: Lead): LeadFormValues {
  return {
    name: lead.name,
    company: lead.company === '—' ? '' : lead.company,
    city: lead.city,
    type: lead.type,
    stage: lead.stage,
    amount: lead.amount > 0 ? String(lead.amount) : '',
    owner: lead.owner,
  }
}

export function useLeadForm(lead: Lead, onSaved: (updated: Lead) => void) {
  const initial = useMemo(() => toForm(lead), [lead])
  const [values, setValues] = useState<LeadFormValues>(initial)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const isDirty = (Object.keys(initial) as (keyof LeadFormValues)[]).some(
    (key) => initial[key] !== values[key],
  )

  const setField = <K extends keyof LeadFormValues>(
    key: K,
    value: LeadFormValues[K],
  ) => {
    setValues((current) => ({ ...current, [key]: value }))
    setError(null)
  }

  const submit = async () => {
    if (values.name.trim() === '') {
      setError('Le nom est obligatoire.')
      return
    }

    const amount = values.amount.trim() === '' ? 0 : Number(values.amount)
    if (Number.isNaN(amount) || amount < 0) {
      setError('Le montant doit être un nombre positif.')
      return
    }

    setIsSaving(true)
    const { data, error: failure } = await updateLead(lead.id, {
      name: values.name.trim(),
      company: values.company.trim() === '' ? '—' : values.company.trim(),
      city: values.city.trim(),
      type: values.type,
      stage: values.stage,
      amount,
      owner: values.owner,
    })
    setIsSaving(false)

    if (failure || !data) {
      setError('Enregistrement impossible. Réessayez.')
      return
    }
    onSaved(data)
  }

  return { values, setField, isDirty, isSaving, error, submit }
}
