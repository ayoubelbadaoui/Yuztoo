import { ArrowDown, Clock, Layers, Mic, MicOff, Play } from 'lucide-react'
import Breadcrumb from '../../components/Breadcrumb.jsx'
import SiteAmbient from '../../components/SiteAmbient.jsx'
import { bt } from '../../components/Brand.jsx'
import { TUTO_HUB, TUTO_THEMES, TUTO_UI } from '../tutorielsContent.js'
import { clock, em } from './TutoText.jsx'

/** Tutorial page header: breadcrumb, meta line, the question as the h1. */
export default function TutoHero({ tuto }) {
  const theme = TUTO_THEMES.find((t) => t.id === tuto.theme)?.label
  return (
    <section className="yz-hero yz-tuto-hero" aria-labelledby="yz-page-title">
      <SiteAmbient variant="grid" />
      <div className="yz-container">
        <Breadcrumb current={`${TUTO_UI.kicker} ${tuto.number}`} parents={[{ href: '/tutoriels', label: TUTO_HUB.crumb }]} />

        <p className="yz-tuto-hero__kicker yz-mono">
          <span className="yz-tuto-hero__num">
            {TUTO_UI.kicker} {tuto.number}
          </span>
          <span>{theme}</span>
        </p>

        <h1 id="yz-page-title" className="yz-tuto-hero__title">
          {em(tuto.question)}
        </h1>
        <p className="yz-tuto-hero__lead">{bt(tuto.lead)}</p>

        <ul className="yz-tuto-hero__facts">
          <li>
            <Clock size={15} strokeWidth={2.4} aria-hidden="true" />
            {clock(tuto.durationSec)}
          </li>
          <li>
            <Layers size={15} strokeWidth={2.4} aria-hidden="true" />
            {tuto.steps.length} {TUTO_UI.steps}
          </li>
          <li className={tuto.voiced ? '' : 'is-silent'}>
            {tuto.voiced ? <Mic size={15} strokeWidth={2.4} aria-hidden="true" /> : <MicOff size={15} strokeWidth={2.4} aria-hidden="true" />}
            {tuto.voiced ? TUTO_UI.voiced : TUTO_UI.silent}
          </li>
        </ul>

        <div className="yz-hero__actions">
          <a className="yz-btn yz-btn--primary" href="#video">
            <Play size={18} strokeWidth={2.4} aria-hidden="true" />
            {TUTO_UI.watch}
          </a>
          <a className="yz-link" href="#etapes">
            <ArrowDown size={14} strokeWidth={2.6} aria-hidden="true" />
            {TUTO_UI.seeSteps}
          </a>
        </div>
      </div>
    </section>
  )
}
