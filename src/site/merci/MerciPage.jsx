import { ArrowRight, CheckCircle2 } from 'lucide-react'
import SiteAmbient from '../components/SiteAmbient.jsx'
import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import { THANKS } from './merciContent.js'
import { bt } from '../components/Brand.jsx'

export default function MerciPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/merci" />
      <main id="contenu" className="yz-section yz-light yz-notfound">
        <SiteAmbient variant="grid" />
        <div className="yz-container yz-notfound__inner">
          <CheckCircle2 className="yz-thanks__icon" size={44} strokeWidth={2} aria-hidden="true" />
          <p className="yz-eyebrow">{bt(THANKS.eyebrow)}</p>
          <h1 className="yz-notfound__title">{bt(THANKS.title)}</h1>
          <p className="yz-lead">{bt(THANKS.lead)}</p>
          <a className="yz-btn yz-btn--primary" href={THANKS.cta.href}>
            {bt(THANKS.cta.label)}
            <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
          </a>
        </div>
      </main>
      <SiteFooter />
    </div>
  )
}
