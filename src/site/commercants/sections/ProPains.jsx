import SectionHead from '../../components/SectionHead.jsx'
import { PRO_IMPACT, PRO_PAINS } from '../commercantsContent.js'

export function ProPains() {
  return (
    <section
      id="constat"
      className="yz-section yz-light--alt yz-pains"
      aria-labelledby="yz-pains-title"
    >
      <div className="yz-container">
        <SectionHead
          index={PRO_PAINS.index}
          eyebrow={PRO_PAINS.eyebrow}
          title={PRO_PAINS.title}
          lead={PRO_PAINS.lead}
          titleId="yz-pains-title"
        />

        <ul className="yz-grid yz-pains__grid">
          {PRO_PAINS.items.map((item, i) => (
            <li
              key={item.id}
              className="yz-cell yz-pains__item"
              data-reveal
              style={{ '--d': `${i * 0.08}s` }}
            >
              <span className="yz-pains__kicker yz-mono">
                <span aria-hidden="true">{String(i + 1).padStart(2, '0')}</span>
                {item.kicker}
              </span>
              <h3 className="yz-pains__title">{item.title}</h3>
              <p className="yz-pains__text">{item.text}</p>
              <ul className="yz-pains__chips">
                {item.chips.map((chip) => (
                  <li key={chip} className="yz-mono">
                    {chip}
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}

export function ProImpact() {
  return (
    <section className="yz-section yz-dark yz-impact" aria-labelledby="yz-impact-title">
      <div className="yz-container">
        <div className="yz-impact__head">
          <p className="yz-eyebrow">{PRO_IMPACT.eyebrow}</p>
          <h2 className="yz-h2" id="yz-impact-title">
            {PRO_IMPACT.title}
          </h2>
        </div>

        <dl className="yz-impact__stats">
          {PRO_IMPACT.stats.map((stat, i) => (
            <div
              key={stat.id}
              className="yz-impact__stat"
              data-reveal
              style={{ '--d': `${i * 0.1}s` }}
            >
              <dt className="yz-impact__label">
                <span className="yz-mono">{stat.label}</span>
                <span className="yz-impact__note">{stat.note}</span>
              </dt>
              <dd className="yz-impact__value">{stat.value}</dd>
            </div>
          ))}
        </dl>
      </div>
    </section>
  )
}
