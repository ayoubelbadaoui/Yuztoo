import { ArrowUp, ArrowUpRight, Mail, MapPin, Phone } from 'lucide-react'
import { ROUTE_META } from '../../routeMeta.js'
import { CONTACT } from '../../siteConfig.js'
import { FOOTER, LOGO } from './navContent.js'
import DownloadBand from './DownloadBand.jsx'
import { StoreButton, STORES } from '../components/StoreButtons.jsx'
import { bt } from '../components/Brand.jsx'

const LIVE_PATHS = new Set(ROUTE_META.filter((route) => route.indexable).map((route) => route.path))

const CONTACT_ITEMS = {
  mail: { Icon: Mail, value: CONTACT.email, href: `mailto:${CONTACT.email}` },
  phone: { Icon: Phone, value: CONTACT.phoneDisplay, href: `tel:${CONTACT.phone}` },
  city: { Icon: MapPin, value: `${CONTACT.city}, France`, href: null },
}

// Pages that are not built yet stay out of the footer instead of showing as
// greyed-out dead links. They appear on their own once added to routeMeta.js.
const isLive = (href) => href.startsWith('mailto:') || LIVE_PATHS.has(href)

function ContactCell({ item }) {
  const { Icon, value, href } = CONTACT_ITEMS[item.kind]
  const body = (
    <>
      <span className="yz-footer__cell-label yz-mono">
        <Icon size={13} strokeWidth={2.4} aria-hidden="true" />
        {bt(item.label)}
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
    <>
    <DownloadBand />
    <footer className="yz-footer">
      <div className="yz-container">
        <div className="yz-footer__top">
          <div className="yz-footer__brandCol">
            <a className="yz-footer__brand" href="/" aria-label="YuzToo, accueil">
              <img src={LOGO.src} width={LOGO.width} height={LOGO.height} alt="" loading="lazy" />
              <span aria-hidden="true">
                Yuz<span>Too</span>
              </span>
            </a>
            <p className="yz-footer__tagline">{bt(FOOTER.tagline)}</p>
            <p className="yz-footer__status yz-mono">
              <span className="yz-footer__pulse" aria-hidden="true" />
              {bt(FOOTER.status)}
            </p>
          </div>

          {FOOTER.columns.map((column, i) => (
            <nav key={column.id} className="yz-footer__col" aria-label={column.title}>
              <h2 className="yz-mono">
                <span aria-hidden="true">{String(i + 1).padStart(2, '0')}</span>
                {bt(column.title)}
              </h2>
              <ul>
                {column.links.filter((link) => isLive(link.href)).map((link) => (
                  <li key={link.href}>
                    <a href={link.href}>{bt(link.label)}</a>
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
            <h2 className="yz-mono">{bt(FOOTER.app.title)}</h2>
            <div className="yz-footer__storelist">
              {STORES.map((store) => (
                <StoreButton key={store.id} store={store} size="sm" />
              ))}
            </div>
          </div>
        </div>

        <div className="yz-footer__legal">
          <span>{bt(FOOTER.legal)}</span>
          <span className="yz-mono">{bt(FOOTER.madeIn)}</span>
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
    </>
  )
}
