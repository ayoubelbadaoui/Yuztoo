import { ArrowRight, Phone } from 'lucide-react'
import { CONTACT } from '../../siteConfig.js'
import LeadForm from './LeadForm.jsx'
import SiteAmbient from './SiteAmbient.jsx'

function PromiseList({ items, compact }) {
  return (
    <dl className={`yz-grid yz-start__promise${compact ? ' yz-start__promise--row' : ''}`} data-reveal>
      {items.map((item) => (
        <div key={item.id} className="yz-start__cell">
          <dt className="yz-mono">{item.label}</dt>
          <dd>{item.value}</dd>
        </div>
      ))}
    </dl>
  )
}

/** Closing dark band: lead form (or mail CTA) + phone, with optional promise figures. */
export default function ContactBand({ band, path, id = 'demarrer' }) {
  const withForm = Boolean(band.form)

  return (
    <section id={id} className="yz-section yz-dark yz-start" aria-labelledby={`${id}-title`}>
      <SiteAmbient variant="grid" />
      <div className={`yz-container yz-start__grid${withForm ? ' yz-start__grid--form' : ''}`}>
        <div className="yz-start__copy">
          <p className="yz-eyebrow">{band.eyebrow}</p>
          <h2 className="yz-closing__title" id={`${id}-title`}>
            {band.title}
          </h2>
          <p className="yz-lead">{band.lead}</p>

          {withForm && band.promise ? <PromiseList items={band.promise} compact /> : null}

          <div className="yz-closing__actions">
            {withForm ? null : (
              <a className="yz-btn yz-btn--primary" href={band.mailCta.href}>
                {band.mailCta.label}
                <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
              </a>
            )}
            <a className="yz-btn yz-btn--ghost" href={`tel:${CONTACT.phone}`}>
              <Phone size={16} strokeWidth={2.4} aria-hidden="true" />
              {CONTACT.phoneDisplay}
            </a>
          </div>
        </div>

        {withForm ? (
          <LeadForm form={band.form} path={path} />
        ) : band.promise ? (
          <PromiseList items={band.promise} />
        ) : null}
      </div>
    </section>
  )
}
