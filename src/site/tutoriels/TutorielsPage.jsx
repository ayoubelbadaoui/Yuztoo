import { Clapperboard } from 'lucide-react'
import SiteHeader from '../sections/SiteHeader.jsx'
import SiteFooter from '../sections/SiteFooter.jsx'
import PageHero from '../components/PageHero.jsx'
import TutoGrid from './sections/TutoGrid.jsx'
import TutoPathStrip from './sections/TutoPathStrip.jsx'
import { TUTORIALS, TUTO_BY_SLUG, TUTO_HUB, tutoPath } from './tutorielsContent.js'

const totalSteps = TUTORIALS.reduce((n, t) => n + t.steps.length, 0)
const totalMin = Math.round(TUTORIALS.reduce((n, t) => n + t.durationSec, 0) / 60)
const figures = { tutos: TUTORIALS.length, steps: totalSteps, time: `${totalMin} min` }

const hero = {
  ...TUTO_HUB,
  primaryCta: { href: tutoPath(TUTO_HUB.primaryCta.slug), label: TUTO_HUB.primaryCta.label },
  checks: TUTO_HUB.stats.map((s) => `${figures[s.id]} ${s.label}`),
}

// Three posters fanned out behind each other: the hero visual.
const FAN = ['tuto-01-creer-mon-compte-commercant', 'tuto-06-bon-de-bienvenue', 'tuto-08-creer-une-promotion']

export default function TutorielsPage() {
  return (
    <div className="yz-page">
      <a className="yz-skip-link" href="#contenu">
        Aller au contenu
      </a>
      <SiteHeader currentPath="/tutoriels" />
      <main id="contenu">
        <PageHero hero={hero} BadgeIcon={Clapperboard} className="yz-thero">
          <div className="yz-thero__fan" aria-hidden="true">
            {FAN.map((slug, i) => {
              const t = TUTO_BY_SLUG[slug]
              return (
                <img
                  key={slug}
                  className={`yz-thero__poster yz-thero__poster--${i + 1}`}
                  src={t.video.poster}
                  width={t.video.width}
                  height={t.video.height}
                  alt=""
                  loading={i === 1 ? 'eager' : 'lazy'}
                  fetchpriority={i === 1 ? 'high' : undefined}
                  decoding="async"
                />
              )
            })}
          </div>
        </PageHero>
        <TutoPathStrip />
        <TutoGrid />
      </main>
      <SiteFooter />
    </div>
  )
}
