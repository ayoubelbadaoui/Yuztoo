import { ArrowLeft, ArrowRight, LayoutGrid } from 'lucide-react'
import { TUTORIALS, TUTO_UI, tutoPath } from '../tutorielsContent.js'

/** Previous / next tutorial in the series, and back to the hub. */
export default function TutoPager({ tuto }) {
  const i = TUTORIALS.findIndex((t) => t.slug === tuto.slug)
  const prev = TUTORIALS[(i - 1 + TUTORIALS.length) % TUTORIALS.length]
  const next = TUTORIALS[(i + 1) % TUTORIALS.length]
  return (
    <nav className="yz-section yz-light--alt yz-section--ruled yz-tpager" aria-label={TUTO_UI.all}>
      <div className="yz-container yz-tpager__grid">
        <a className="yz-tpager__link" href={tutoPath(prev.slug)} rel="prev">
          <span className="yz-mono">
            <ArrowLeft size={14} strokeWidth={2.6} aria-hidden="true" />
            {TUTO_UI.prev}
          </span>
          <span className="yz-tpager__title">
            {TUTO_UI.kicker} {prev.number} — {prev.title}
          </span>
        </a>
        <a className="yz-tpager__all" href="/tutoriels">
          <LayoutGrid size={18} strokeWidth={2.4} aria-hidden="true" />
          {TUTO_UI.all}
        </a>
        <a className="yz-tpager__link yz-tpager__link--next" href={tutoPath(next.slug)} rel="next">
          <span className="yz-mono">
            {TUTO_UI.next}
            <ArrowRight size={14} strokeWidth={2.6} aria-hidden="true" />
          </span>
          <span className="yz-tpager__title">
            {TUTO_UI.kicker} {next.number} — {next.title}
          </span>
        </a>
      </div>
    </nav>
  )
}
