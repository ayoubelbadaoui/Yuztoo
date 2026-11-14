import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import ContactBand from '../components/ContactBand.jsx'
import FaqSection from '../components/FaqSection.jsx'
import StatBand from '../components/StatBand.jsx'
import CliHero from './sections/CliHero.jsx'
import { CliLocal, CliMessages, CliSteps, CliWhy } from './sections/CliSections.jsx'
import { CLI_DATA, CLI_FAQ, CLI_START } from './clientsContent.js'

export default function ClientsPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/pour-clients" />
      <main id="contenu">
        <CliHero />
        <CliWhy />
        <CliSteps />
        <CliMessages />
        <CliLocal />
        <StatBand band={CLI_DATA} id="yz-data" />
        <FaqSection faq={CLI_FAQ} />
        <ContactBand band={CLI_START} id="recommander" />
      </main>
      <SiteFooter />
    </div>
  )
}
