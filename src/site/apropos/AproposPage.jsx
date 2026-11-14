import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import ContactBand from '../components/ContactBand.jsx'
import {
  AboutAmbition,
  AboutFounder,
  AboutHero,
  AboutMission,
  AboutVision,
} from './sections/AboutSections.jsx'
import { ABOUT_CONTACT } from './aproposContent.js'

export default function AproposPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/a-propos" />
      <main id="contenu">
        <AboutHero />
        <AboutMission />
        <AboutVision />
        <AboutFounder />
        <AboutAmbition />
        <ContactBand band={ABOUT_CONTACT} path="/a-propos" id="contact" />
      </main>
      <SiteFooter />
    </div>
  )
}
