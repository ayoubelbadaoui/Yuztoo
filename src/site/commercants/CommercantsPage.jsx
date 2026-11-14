import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import ProHero from './sections/ProHero.jsx'
import { ProImpact, ProPains } from './sections/ProPains.jsx'
import ProSetup from './sections/ProSetup.jsx'
import ProClients from './sections/ProClients.jsx'
import ProLoyalty from './sections/ProLoyalty.jsx'
import ProTools from './sections/ProTools.jsx'
import ProFaq from './sections/ProFaq.jsx'
import ProStart from './sections/ProStart.jsx'

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
        <ProImpact />
        <ProSetup />
        <ProClients />
        <ProLoyalty />
        <ProTools />
        <ProFaq />
        <ProStart />
      </main>
      <SiteFooter />
    </div>
  )
}
