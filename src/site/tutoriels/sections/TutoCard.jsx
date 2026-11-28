import { Play } from 'lucide-react'
import { TUTO_THEMES, TUTO_UI, tutoPath } from '../tutorielsContent.js'
import { clock, em } from './TutoText.jsx'

const themeLabel = (id) => TUTO_THEMES.find((t) => t.id === id)?.label ?? ''

/** Poster card linking to a tutorial page. */
export default function TutoCard({ tuto, headingLevel = 3 }) {
  const Heading = `h${headingLevel}`
  return (
    <a className="yz-tcard" href={tutoPath(tuto.slug)} data-theme-id={tuto.theme}>
      <span className="yz-tcard__media">
        <img
          src={tuto.video.poster}
          width={tuto.video.width}
          height={tuto.video.height}
          alt=""
          loading="lazy"
          decoding="async"
        />
        <span className="yz-tcard__play" aria-hidden="true">
          <Play size={18} strokeWidth={2.6} />
        </span>
        <span className="yz-tcard__dur yz-mono">{clock(tuto.durationSec)}</span>
      </span>
      <span className="yz-tcard__body">
        <span className="yz-tcard__kicker yz-mono">
          {TUTO_UI.kicker} {tuto.number} · {themeLabel(tuto.theme)}
        </span>
        <Heading className="yz-tcard__title">{em(tuto.question)}</Heading>
        <span className="yz-tcard__meta">
          {tuto.steps.length} {TUTO_UI.steps}
          <span className={`yz-tcard__voice${tuto.voiced ? '' : ' is-silent'}`}>
            {tuto.voiced ? TUTO_UI.voiced : TUTO_UI.silent}
          </span>
        </span>
      </span>
    </a>
  )
}
