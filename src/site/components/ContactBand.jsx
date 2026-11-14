import { ArrowRight, Phone } from 'lucide-react'
import { CONTACT } from '../../siteConfig.js'
import SiteAmbient from './SiteAmbient.jsx'

/** Closing dark band: mail CTA + phone, with an optional promise column. */
export default function ContactBand({ band, id = 'demarrer' }) {
  return (
    <section id={id} className="yz-section yz-dark yz-start" aria-labelledby={`${id}-title`}>
      <SiteAmbient variant="grid" />
      <div className="yz-container yz-start__grid">
        <div>
          <p className="yz-eyebrow">{band.eyebrow}</p>
          <h2 className="yz-closing__title" id={`${id}-title`}>
            {band.title}
          </h2>
          <p className="yz-lead">{band.lead}</p>

          <div className="yz-closing__actions">
            <a className="yz-btn yz-btn--primary" href={band.mailCta.href}>
              {band.mailCta.label}
              <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
            </a>
            <a className="yz-btn yz-btn--ghost" href={`tel:${CONTACT.phone}`}>
              <Phone size={16} strokeWidth={2.4} aria-hidden="true" />
              {CONTACT.phoneDisplay}
            </a>
          </div>
        </div>

        {band.promise ? (
          <dl className="yz-grid yz-start__promise" data-reveal>
            {band.promise.map((item) => (
              <div key={item.id} className="yz-start__cell">
                <dt className="yz-mono">{item.label}</dt>
                <dd>{item.value}</dd>
              </div>
            ))}
          </dl>
        ) : null}
      </div>
    </section>
  )
}
