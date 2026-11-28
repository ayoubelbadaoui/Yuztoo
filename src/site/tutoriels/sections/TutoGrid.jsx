import { useState } from 'react'
import SectionHead from '../../components/SectionHead.jsx'
import { TUTORIALS, TUTO_HUB, TUTO_THEMES } from '../tutorielsContent.js'
import TutoCard from './TutoCard.jsx'

/** Every tutorial, filterable by theme (all shown in the prerendered HTML). */
export default function TutoGrid() {
  const [theme, setTheme] = useState('tous')
  const shown = theme === 'tous' ? TUTORIALS : TUTORIALS.filter((t) => t.theme === theme)
  const counts = Object.fromEntries(
    TUTO_THEMES.map((th) => [th.id, th.id === 'tous' ? TUTORIALS.length : TUTORIALS.filter((t) => t.theme === th.id).length]),
  )

  return (
    <section className="yz-section yz-light yz-tgrid" id="tous-les-tutoriels" aria-labelledby="yz-tgrid-title">
      <div className="yz-container">
        <SectionHead eyebrow={TUTO_HUB.badge} title={TUTO_HUB.gridTitle} lead={TUTO_HUB.gridLead} titleId="yz-tgrid-title" />

        <div className="yz-tgrid__filters" role="group" aria-label={TUTO_HUB.filterLabel}>
          {TUTO_THEMES.map((th) => (
            <button
              key={th.id}
              type="button"
              className={`yz-chip${theme === th.id ? ' is-on' : ''}`}
              aria-pressed={theme === th.id}
              onClick={() => setTheme(th.id)}
            >
              {th.label}
              <span className="yz-chip__count yz-mono">{counts[th.id]}</span>
            </button>
          ))}
        </div>

        {shown.length ? (
          <ul className="yz-tgrid__list" aria-live="polite">
            {shown.map((t) => (
              <li key={t.slug}>
                <TutoCard tuto={t} />
              </li>
            ))}
          </ul>
        ) : (
          <p className="yz-tgrid__empty">{TUTO_HUB.empty}</p>
        )}
      </div>
    </section>
  )
}
