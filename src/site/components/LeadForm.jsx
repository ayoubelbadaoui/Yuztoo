import { useId } from 'react'
import { ArrowRight } from 'lucide-react'
import { CONTACT } from '../../siteConfig.js'
import { leadSourceFor } from '../../data/leadSources.js'
import { FORM_COPY } from '../forms/formContent.js'
import { useLeadFormState } from '../forms/useLeadFormState.js'
import { useLeadSubmit } from '../forms/useLeadSubmit.js'
import { bt } from './Brand.jsx'

function Field({ id, label, hint, error, children }) {
  return (
    <div className={`yz-field${error ? ' is-invalid' : ''}`}>
      <label htmlFor={id}>
        {label}
        {hint ? <span className="yz-field__hint"> ({hint})</span> : null}
      </label>
      {children}
      {error ? (
        <p className="yz-field__error" id={`${id}-error`}>
          {FORM_COPY.errors[error]}
        </p>
      ) : null}
    </div>
  )
}

/**
 * Shared lead form (SEO_HOLY_BOOK §11): 48 px fields, 16 px inputs, honeypot,
 * consent linking to /confidentialite, thank-you page on success.
 */
export default function LeadForm({ form, path, source }) {
  const uid = useId()
  const { values, errors, onChange, check } = useLeadFormState()
  const { status, error, send } = useLeadSubmit({ source: leadSourceFor(path, source), kind: form.kind })
  const sending = status !== 'idle'

  const onSubmit = (event) => {
    event.preventDefault()
    if (sending || !check()) return
    send(values)
  }

  const fieldId = (name) => `${uid}-${name}`
  const describedBy = (name) => (errors[name] ? `${fieldId(name)}-error` : undefined)

  return (
    <form className="yz-form" onSubmit={onSubmit} noValidate aria-labelledby={fieldId('title')}>
      <p className="yz-form__title" id={fieldId('title')}>
        {bt(form.title)}
      </p>

      <div className="yz-form__row">
        <Field id={fieldId('name')} label={FORM_COPY.name.label} error={errors.name}>
          <input
            id={fieldId('name')} name="name" type="text" maxLength={80} required
            autoComplete={FORM_COPY.name.autoComplete} value={values.name} onChange={onChange}
            aria-invalid={Boolean(errors.name)} aria-describedby={describedBy('name')}
          />
        </Field>
        <Field id={fieldId('email')} label={FORM_COPY.email.label} error={errors.email}>
          <input
            id={fieldId('email')} name="email" type="email" maxLength={120} required inputMode="email"
            autoComplete={FORM_COPY.email.autoComplete} value={values.email} onChange={onChange}
            aria-invalid={Boolean(errors.email)} aria-describedby={describedBy('email')}
          />
        </Field>
      </div>

      <div className="yz-form__row">
        <Field id={fieldId('phone')} label={FORM_COPY.phone.label} hint={FORM_COPY.optional}>
          <input
            id={fieldId('phone')} name="phone" type="tel" maxLength={20} inputMode="tel"
            autoComplete={FORM_COPY.phone.autoComplete} value={values.phone} onChange={onChange}
          />
        </Field>
        {form.orgLabel ? (
          <Field id={fieldId('organisation')} label={form.orgLabel} hint={form.orgRequired ? null : FORM_COPY.optional}>
            <input
              id={fieldId('organisation')} name="organisation" type="text" maxLength={120}
              autoComplete={form.orgAutoComplete} value={values.organisation} onChange={onChange}
            />
          </Field>
        ) : null}
      </div>

      <Field id={fieldId('message')} label={form.messageLabel} hint={FORM_COPY.optional}>
        <textarea
          id={fieldId('message')} name="message" rows={3} maxLength={1000}
          placeholder={form.messagePlaceholder} value={values.message} onChange={onChange}
        />
      </Field>

      <div className="yz-form__trap" aria-hidden="true">
        <label htmlFor={fieldId('website')}>{FORM_COPY.honeypot}</label>
        <input
          id={fieldId('website')} name="website" type="text" tabIndex={-1} autoComplete="off"
          value={values.website} onChange={onChange}
        />
      </div>

      <div className={`yz-consent${errors.consent ? ' is-invalid' : ''}`}>
        <input
          id={fieldId('consent')} name="consent" type="checkbox" checked={values.consent} onChange={onChange}
          aria-invalid={Boolean(errors.consent)} aria-describedby={describedBy('consent')}
        />
        <label htmlFor={fieldId('consent')}>
          {bt(FORM_COPY.consentLead)}
          <a href={FORM_COPY.consentLink.href}>{bt(FORM_COPY.consentLink.label)}</a>
        </label>
        {errors.consent ? (
          <p className="yz-field__error" id={`${fieldId('consent')}-error`}>
            {FORM_COPY.errors.consent}
          </p>
        ) : null}
      </div>

      <button className="yz-btn yz-btn--primary yz-form__submit" type="submit" disabled={sending}>
        {sending ? FORM_COPY.sending : form.submit}
        <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
      </button>

      <p className="yz-form__status" role="status" aria-live="polite">
        {error ? FORM_COPY.errors[error] : null}
      </p>

      <p className="yz-form__fallback">
        {FORM_COPY.fallbackLead}
        <a href={`mailto:${CONTACT.email}`}>{CONTACT.email}</a>
      </p>
    </form>
  )
}
