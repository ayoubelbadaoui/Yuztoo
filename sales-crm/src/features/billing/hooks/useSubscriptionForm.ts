import { useMemo, useState } from 'react'

import type {
  PaymentMethod,
  Subscription,
  SubscriptionStatus,
} from '@/features/billing/domain/subscription'
import {
  setSubscriptionStatus,
  updateSubscription,
} from '@/features/billing/services/billingService'

export type SubscriptionFormValues = {
  monthlyAmount: string
  billingDay: string
  engagementMonths: string
  paymentMethod: PaymentMethod
  owner: string
}

function toForm(subscription: Subscription): SubscriptionFormValues {
  return {
    monthlyAmount: String(subscription.monthlyAmount),
    billingDay: String(subscription.billingDay),
    engagementMonths: String(subscription.engagementMonths),
    paymentMethod: subscription.paymentMethod,
    owner: subscription.owner,
  }
}

export function useSubscriptionForm(
  subscription: Subscription,
  onDone: () => void,
) {
  const initial = useMemo(() => toForm(subscription), [subscription])
  const [values, setValues] = useState<SubscriptionFormValues>(initial)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const isDirty = (
    Object.keys(initial) as (keyof SubscriptionFormValues)[]
  ).some((key) => initial[key] !== values[key])

  const setField = <K extends keyof SubscriptionFormValues>(
    key: K,
    value: SubscriptionFormValues[K],
  ) => {
    setValues((current) => ({ ...current, [key]: value }))
    setError(null)
  }

  const submit = async () => {
    const monthlyAmount = Number(values.monthlyAmount)
    const billingDay = Number(values.billingDay)
    const engagementMonths = Number(values.engagementMonths)

    if (Number.isNaN(monthlyAmount) || monthlyAmount < 0) {
      setError('Le montant mensuel doit être un nombre positif.')
      return
    }
    if (billingDay < 1 || billingDay > 28) {
      setError('Le jour de prélèvement doit être compris entre 1 et 28.')
      return
    }

    setIsSaving(true)
    const { error: failure } = await updateSubscription(subscription.id, {
      monthlyAmount,
      billingDay,
      engagementMonths,
      paymentMethod: values.paymentMethod,
      owner: values.owner,
    })
    setIsSaving(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onDone()
  }

  const changeStatus = async (status: SubscriptionStatus) => {
    setIsSaving(true)
    const { error: failure } = await setSubscriptionStatus(
      subscription.id,
      status,
    )
    setIsSaving(false)

    if (failure) {
      setError(failure.message)
      return
    }
    onDone()
  }

  return { values, setField, isDirty, isSaving, error, submit, changeStatus }
}
