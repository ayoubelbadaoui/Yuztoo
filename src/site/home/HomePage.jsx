import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import HomeHero from './sections/HomeHero.jsx'
import HomePizza from './sections/HomePizza.jsx'
import HomeSteps from './sections/HomeSteps.jsx'
import HomeBenefits from './sections/HomeBenefits.jsx'
import HomeCoverage from './sections/HomeCoverage.jsx'
import HomeTestimonials from './sections/HomeTestimonials.jsx'
import HomeFounder from './sections/HomeFounder.jsx'
import HomeAudiences from './sections/HomeAudiences.jsx'
import HomeClosing from './sections/HomeClosing.jsx'

export default function HomePage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/" />
      <main id="contenu">
        <HomeHero />
        <HomePizza />
        <HomeSteps />
        <HomeBenefits />
        <HomeCoverage />
        <HomeTestimonials />
        <HomeFounder />
        <HomeAudiences />
        <HomeClosing />
      </main>
      <SiteFooter />
    </div>
  )
}
