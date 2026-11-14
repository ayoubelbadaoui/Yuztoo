import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import ContactBand from '../components/ContactBand.jsx'
import FaqSection from '../components/FaqSection.jsx'
import StatBand from '../components/StatBand.jsx'
import ProHero from './sections/ProHero.jsx'
import ProPains from './sections/ProPains.jsx'
import ProSetup from './sections/ProSetup.jsx'
import ProClients from './sections/ProClients.jsx'
import ProLoyalty from './sections/ProLoyalty.jsx'
import ProTools from './sections/ProTools.jsx'
import { PRO_FAQ, PRO_IMPACT, PRO_START } from './commercantsContent.js'

export default function CommercantsPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/pour-commercants" />
      <main id="contenu">
        <ProHero />
        <ProPains />
        <StatBand band={PRO_IMPACT} id="yz-impact" />
        <ProSetup />
        <ProClients />
        <ProLoyalty />
        <ProTools />
        <FaqSection faq={PRO_FAQ} />
        <ContactBand band={PRO_START} />
      </main>
      <SiteFooter />
    </div>
  )
}
