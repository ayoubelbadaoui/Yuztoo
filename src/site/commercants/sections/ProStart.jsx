import { ArrowRight, Phone } from 'lucide-react'
import { CONTACT } from '../../../siteConfig.js'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import { PRO_START } from '../commercantsContent.js'

export default function ProStart() {
  return (
    <section
      id="demarrer"
      className="yz-section yz-dark yz-start"
      aria-labelledby="yz-start-title"
    >
      <SiteAmbient variant="grid" />
      <div className="yz-container yz-start__grid">
        <div>
          <p className="yz-eyebrow">{PRO_START.eyebrow}</p>
          <h2 className="yz-closing__title" id="yz-start-title">
            {PRO_START.title}
          </h2>
          <p className="yz-lead">{PRO_START.lead}</p>

          <div className="yz-closing__actions">
            <a className="yz-btn yz-btn--primary" href={PRO_START.mailCta.href}>
              {PRO_START.mailCta.label}
              <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
            </a>
            <a className="yz-btn yz-btn--ghost" href={`tel:${CONTACT.phone}`}>
              <Phone size={16} strokeWidth={2.4} aria-hidden="true" />
              {CONTACT.phoneDisplay}
            </a>
          </div>
        </div>

        <dl className="yz-grid yz-start__promise" data-reveal>
          {PRO_START.promise.map((item) => (
            <div key={item.id} className="yz-start__cell">
              <dt className="yz-mono">{item.label}</dt>
              <dd>{item.value}</dd>
            </div>
          ))}
        </dl>
      </div>
    </section>
  )
}
