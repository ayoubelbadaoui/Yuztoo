import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import TutoHero from './sections/TutoHero.jsx'
import TutoLesson from './sections/TutoLesson.jsx'
import TutoPager from './sections/TutoPager.jsx'
import { tutoPath } from './tutorielsContent.js'

export default function TutorielPage({ tuto }) {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath={tutoPath(tuto.slug)} />
      <main id="contenu">
        <TutoHero tuto={tuto} />
        <TutoLesson tuto={tuto} />
        <TutoPager tuto={tuto} />
      </main>
      <SiteFooter />
    </div>
  )
}

/** One page component per tutorial, for the route table. */
export function tutorielRoute(tuto) {
  const Route = () => <TutorielPage tuto={tuto} />
  Route.displayName = `Tutoriel(${tuto.slug})`
  return Route
}
