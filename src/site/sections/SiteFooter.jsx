import { Mail, MapPin, Phone } from 'lucide-react'
import { CONTACT } from '../../siteConfig.js'
import { FOOTER, LOGO } from './navContent.js'

export default function SiteFooter() {
  return (
    <footer className="yz-footer">
      <div className="yz-container">
        <div className="yz-footer__grid">
          <div className="yz-footer__brandCol">
            <a className="yz-footer__brand" href="/" aria-label="Yuztoo, accueil">
              <img src={LOGO.src} width={LOGO.width} height={LOGO.height} alt="" loading="lazy" />
              <span aria-hidden="true">
                Yuz<span>too</span>
              </span>
            </a>
            <p className="yz-footer__tagline">{FOOTER.tagline}</p>
            <ul className="yz-footer__contact">
              <li>
                <a href={`mailto:${CONTACT.email}`}>
                  <Mail size={15} aria-hidden="true" />
                  {CONTACT.email}
                </a>
              </li>
              <li>
                <a href={`tel:${CONTACT.phone}`}>
                  <Phone size={15} aria-hidden="true" />
                  {CONTACT.phoneDisplay}
                </a>
              </li>
              <li>
                <span>
                  <MapPin size={15} aria-hidden="true" />
                  {CONTACT.city}, France
                </span>
              </li>
            </ul>
          </div>

          {FOOTER.columns.map((column) => (
            <nav key={column.id} className="yz-footer__col" aria-label={column.title}>
              <h2>{column.title}</h2>
              <ul>
                {column.links.map((link) => (
                  <li key={link.href}>
                    <a href={link.href}>{link.label}</a>
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        <div className="yz-footer__legal">
          <span>{FOOTER.legal}</span>
          <span className="yz-mono">{FOOTER.madeIn}</span>
        </div>
      </div>
    </footer>
  )
}
