import { ArrowRight, Phone } from 'lucide-react'
import { APP_STORES, CONTACT } from '../../../siteConfig.js'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import { HOME_CLOSING } from '../homeContent.js'

export default function HomeClosing() {
  const { image, plate } = HOME_CLOSING

  return (
    <section className="yz-section yz-dark yz-closing" aria-labelledby="yz-closing-title">
      <SiteAmbient variant="grid" />
      <div className="yz-container yz-closing__grid">
        <div className="yz-closing__copy">
          <p className="yz-eyebrow">{HOME_CLOSING.eyebrow}</p>
          <h2 className="yz-closing__title" id="yz-closing-title">
            {HOME_CLOSING.title}
          </h2>
          <p className="yz-lead">{HOME_CLOSING.lead}</p>

          <div className="yz-closing__actions">
            <a className="yz-btn yz-btn--primary" href={HOME_CLOSING.primaryCta.href}>
              {HOME_CLOSING.primaryCta.label}
              <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
            </a>
            {APP_STORES.available ? (
              <a className="yz-btn yz-btn--ghost" href="/telecharger">
                {HOME_CLOSING.downloadCta}
              </a>
            ) : (
              <a className="yz-btn yz-btn--ghost" href={`tel:${CONTACT.phone}`}>
                <Phone size={16} strokeWidth={2.4} aria-hidden="true" />
                {CONTACT.phoneDisplay}
              </a>
            )}
          </div>
        </div>

        <div className="yz-closing__visual yz-frame" data-reveal>
          <img
            src={image.src}
            alt={image.alt}
            width={image.width}
            height={image.height}
            loading="lazy"
            decoding="async"
          />
          <div className="yz-closing__plate">
            <span className="yz-mono">{plate.kicker}</span>
            <strong>{plate.value}</strong>
            <span>{plate.note}</span>
          </div>
        </div>
      </div>
    </section>
  )
}
