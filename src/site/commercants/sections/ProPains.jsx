import SectionHead from '../../components/SectionHead.jsx'
import { PRO_PAINS } from '../commercantsContent.js'

export default function ProPains() {
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
