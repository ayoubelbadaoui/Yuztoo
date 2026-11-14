import { useState } from 'react'
import { submitLead } from '../../data/submitLead.js'

export const THANKS_PATH = '/merci'

/** Sends a validated lead and moves to the thank-you page on success. */
export function useLeadSubmit({ source, kind }) {
  const [status, setStatus] = useState('idle')
  const [error, setError] = useState(null)

  const send = async (values) => {
    setStatus('sending')
    setError(null)
    const { error: failure } = await submitLead({
      source,
      kind,
      fields: {
        name: values.name.trim(),
        email: values.email.trim(),
        phone: values.phone.trim(),
        organisation: values.organisation.trim(),
        message: values.message.trim(),
        consent: values.consent,
        website: values.website,
      },
    })
    if (failure) {
      setStatus('idle')
      setError(failure)
      return
    }
    setStatus('sent')
    window.location.assign(THANKS_PATH)
  }

  return { status, error, send }
}
