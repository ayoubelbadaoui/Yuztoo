import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import ContactBand from '../components/ContactBand.jsx'
import FaqSection from '../components/FaqSection.jsx'
import StatBand from '../components/StatBand.jsx'
import ColHero from './sections/ColHero.jsx'
import { ColAnswer, ColBenefits, ColInvest, ColProblem, ColPromise } from './sections/ColSections.jsx'
import CtaStrip from '../components/CtaStrip.jsx'
import { COL_CTA, COL_FAQ, COL_IMPACT, COL_START } from './collectivitesContent.js'

export default function CollectivitesPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/pour-collectivites" />
      <main id="contenu">
        <ColHero />
        <ColProblem />
        <StatBand band={COL_IMPACT} id="yz-col-impact" />
        <ColAnswer />
        <ColPromise />
        <CtaStrip cta={COL_CTA} />
        <ColBenefits />
        <ColInvest />
        <FaqSection faq={COL_FAQ} />
        <ContactBand band={COL_START} path="/pour-collectivites" id="deployer" />
      </main>
      <SiteFooter />
    </div>
  )
}
