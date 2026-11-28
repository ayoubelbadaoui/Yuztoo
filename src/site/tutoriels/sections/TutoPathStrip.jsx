import { ArrowRight } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { TUTO_BY_SLUG, TUTO_HUB, TUTO_UI, tutoPath } from '../tutorielsContent.js'
import { clock, plain } from './TutoText.jsx'

/** « Vous débutez ? » — five tutorials in order, as a numbered rail. */
export default function TutoPathStrip() {
  const { path } = TUTO_HUB
  return (
    <section className="yz-section yz-light--alt yz-section--ruled yz-tpath" aria-labelledby="yz-tpath-title">
      <div className="yz-container">
        <SectionHead eyebrow="Parcours" title={path.title} lead={path.lead} titleId="yz-tpath-title" />
        <ol className="yz-tpath__rail">
          {path.slugs.map((slug, i) => {
            const t = TUTO_BY_SLUG[slug]
            return (
              <li key={slug} className="yz-tpath__item">
                <a href={tutoPath(slug)}>
                  <span className="yz-tpath__n yz-mono">
                    <span className="yz-tpath__step">{String(i + 1).padStart(2, '0')}</span>
                    {TUTO_UI.kicker} {t.number}
                  </span>
                  <span className="yz-tpath__title">{t.title}</span>
                  <span className="yz-tpath__meta yz-mono">{clock(t.durationSec)}</span>
                  <span className="yz-tpath__q">{plain(t.question)}</span>
                  <ArrowRight className="yz-tpath__go" size={16} strokeWidth={2.4} aria-hidden="true" />
                </a>
              </li>
            )
          })}
        </ol>
      </div>
    </section>
  )
}
