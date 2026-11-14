import { ArrowRight, ArrowUpRight, Landmark, Smartphone, Store } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { HOME_AUDIENCES } from '../homeContent.js'

const ICONS = { store: Store, phone: Smartphone, landmark: Landmark }

export default function HomeAudiences() {
  return (
    <section
      className="yz-section yz-light yz-light--alt yz-section--ruled"
      aria-labelledby="yz-audiences-title"
    >
      <div className="yz-container">
        <SectionHead
          index={HOME_AUDIENCES.index}
          eyebrow={HOME_AUDIENCES.eyebrow}
          title={HOME_AUDIENCES.title}
          align="center"
          titleId="yz-audiences-title"
        />

        <ul className="yz-grid yz-audiences">
          {HOME_AUDIENCES.cards.map((card, i) => {
            const Icon = ICONS[card.icon]
            return (
              <li key={card.id} className="yz-cell" data-reveal style={{ '--d': `${i * 0.08}s` }}>
                <a className="yz-audience" href={card.href}>
                  <span className="yz-audience__head">
                    <span className="yz-tile" aria-hidden="true">
                      <Icon size={21} strokeWidth={2.1} />
                    </span>
                    <ArrowUpRight className="yz-audience__corner" size={20} aria-hidden="true" />
                  </span>
                  <span className="yz-audience__idx yz-mono">{String(i + 1).padStart(2, '0')}</span>
                  <h3 className="yz-audience__title">{card.title}</h3>
                  <p className="yz-audience__text">{card.text}</p>
                  <span className="yz-audience__cta yz-mono">
                    {card.cta}
                    <ArrowRight size={14} strokeWidth={2.6} aria-hidden="true" />
                  </span>
                </a>
              </li>
            )
          })}
        </ul>
      </div>
    </section>
  )
}
