import { ArrowUp, ArrowUpRight, Mail, MapPin, Phone, Smartphone } from 'lucide-react'
import { ROUTE_META } from '../../routeMeta.js'
import { APP_STORES, CONTACT } from '../../siteConfig.js'
import { FOOTER, LOGO } from './navContent.js'

const LIVE_PATHS = new Set(ROUTE_META.filter((route) => route.indexable).map((route) => route.path))

const CONTACT_ITEMS = {
  mail: { Icon: Mail, value: CONTACT.email, href: `mailto:${CONTACT.email}` },
  phone: { Icon: Phone, value: CONTACT.phoneDisplay, href: `tel:${CONTACT.phone}` },
  city: { Icon: MapPin, value: `${CONTACT.city}, France`, href: null },
}

function FooterLink({ link }) {
  if (LIVE_PATHS.has(link.href)) {
    return <a href={link.href}>{link.label}</a>
  }
  return (
    <span className="yz-footer__soon">
      {link.label}
      <span className="yz-sr-only"> ({FOOTER.soon.toLowerCase()})</span>
    </span>
  )
}

function ContactCell({ item }) {
  const { Icon, value, href } = CONTACT_ITEMS[item.kind]
  const body = (
    <>
      <span className="yz-footer__cell-label yz-mono">
        <Icon size={13} strokeWidth={2.4} aria-hidden="true" />
        {item.label}
      </span>
      <span className="yz-footer__cell-value">{value}</span>
      {href ? <ArrowUpRight className="yz-footer__cell-arrow" size={18} aria-hidden="true" /> : null}
    </>
  )
  return href ? (
    <a className="yz-footer__cell" href={href}>
      {body}
    </a>
  ) : (
    <div className="yz-footer__cell">{body}</div>
  )
}

export default function SiteFooter() {
  return (
    <footer className="yz-footer">
      <div className="yz-container">
        <div className="yz-footer__top">
          <div className="yz-footer__brandCol">
            <a className="yz-footer__brand" href="/" aria-label="Yuztoo, accueil">
              <img src={LOGO.src} width={LOGO.width} height={LOGO.height} alt="" loading="lazy" />
              <span aria-hidden="true">
                Yuz<span>too</span>
              </span>
            </a>
            <p className="yz-footer__tagline">{FOOTER.tagline}</p>
            <p className="yz-footer__status yz-mono">
              <span className="yz-footer__pulse" aria-hidden="true" />
              {FOOTER.status}
            </p>
          </div>

          {FOOTER.columns.map((column, i) => (
            <nav key={column.id} className="yz-footer__col" aria-label={column.title}>
              <h2 className="yz-mono">
                <span aria-hidden="true">{String(i + 1).padStart(2, '0')}</span>
                {column.title}
              </h2>
              <ul>
                {column.links.map((link) => (
                  <li key={link.href}>
                    <FooterLink link={link} />
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        <div className="yz-footer__mid">
          <div className="yz-footer__cells">
            {FOOTER.contact.map((item) => (
              <ContactCell key={item.id} item={item} />
            ))}
          </div>

          <div className="yz-footer__app">
            <h2 className="yz-mono">{FOOTER.app.title}</h2>
            <ul>
              {FOOTER.app.stores.map((store) => {
                const href = APP_STORES.available ? APP_STORES[store.id] : null
                return (
                  <li key={store.id}>
                    {href ? (
                      <a className="yz-footer__store" href={href}>
                        <Smartphone size={18} aria-hidden="true" />
                        {store.label}
                      </a>
                    ) : (
                      <span className="yz-footer__store is-soon">
                        <Smartphone size={18} aria-hidden="true" />
                        {store.label}
                        <em className="yz-mono">{FOOTER.soon}</em>
                      </span>
                    )}
                  </li>
                )
              })}
            </ul>
          </div>
        </div>

        <div className="yz-footer__legal">
          <span>{FOOTER.legal}</span>
          <span className="yz-mono">{FOOTER.madeIn}</span>
          <a className="yz-footer__top-link yz-mono" href="#top">
            {FOOTER.backToTop}
            <ArrowUp size={14} strokeWidth={2.4} aria-hidden="true" />
          </a>
        </div>
      </div>

      <p className="yz-footer__wordmark" aria-hidden="true">
        {FOOTER.wordmark.slice(0, 3)}
        <span>{FOOTER.wordmark.slice(3)}</span>
      </p>
    </footer>
  )
}
