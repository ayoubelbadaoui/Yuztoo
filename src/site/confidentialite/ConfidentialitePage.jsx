import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import Breadcrumb from '../components/Breadcrumb.jsx'
import { PRIVACY_HERO, PRIVACY_SECTIONS } from './confidentialiteContent.js'
import { bt } from '../components/Brand.jsx'

export default function ConfidentialitePage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/confidentialite" />
      <main id="contenu" className="yz-section yz-light yz-legal">
        <div className="yz-container yz-legal__inner">
          <Breadcrumb current={PRIVACY_HERO.crumb} />
          <h1 className="yz-legal__title">{bt(PRIVACY_HERO.title)}</h1>
          <p className="yz-lead">{bt(PRIVACY_HERO.lead)}</p>
          <p className="yz-legal__updated yz-mono">{PRIVACY_HERO.updated}</p>
          <p className="yz-legal__intro">{bt(PRIVACY_HERO.intro)}</p>

          {PRIVACY_SECTIONS.map((section) => (
            <section key={section.id} id={section.id} className="yz-legal__section" aria-labelledby={`${section.id}-title`}>
              <h2 id={`${section.id}-title`}>{bt(section.title)}</h2>
              {section.paragraphs.map((text) => (
                <p key={text}>{bt(text)}</p>
              ))}
              {section.list ? (
                <ul>
                  {section.list.map((item) => (
                    <li key={item}>{bt(item)}</li>
                  ))}
                </ul>
              ) : null}
              {section.after ? <p>{section.after}</p> : null}
            </section>
          ))}
        </div>
      </main>
      <SiteFooter />
    </div>
  )
}
