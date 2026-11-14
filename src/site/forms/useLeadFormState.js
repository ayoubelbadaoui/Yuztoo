import { useState } from 'react'

const EMPTY = { name: '', email: '', phone: '', organisation: '', message: '', consent: false, website: '' }
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

export function validateLead(values) {
  const errors = {}
  if (values.name.trim().length < 2) errors.name = 'name'
  if (!EMAIL.test(values.email.trim())) errors.email = 'email'
  if (!values.consent) errors.consent = 'consent'
  return errors
}

/** Field values and per-field errors for a lead form. */
export function useLeadFormState() {
  const [values, setValues] = useState(EMPTY)
  const [errors, setErrors] = useState({})

  const onChange = (event) => {
    const { name, type, checked, value } = event.target
    setValues((prev) => ({ ...prev, [name]: type === 'checkbox' ? checked : value }))
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: undefined }))
  }

  const check = () => {
    const next = validateLead(values)
    setErrors(next)
    return Object.keys(next).length === 0
  }

  return { values, errors, onChange, check }
}
