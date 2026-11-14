import { Check, Gift } from 'lucide-react'
import CheckColumns from '../../components/CheckColumns.jsx'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_LOYALTY } from '../commercantsContent.js'

function StampCard({ card }) {
  const stamps = Array.from({ length: card.total }, (_, i) => i < card.filled)

  return (
    <div className="yz-stamp" data-reveal>
      <div className="yz-stamp__head">
        <span className="yz-mono">{card.shop}</span>
        <img src="/images/yuztoo/yuztoo-mascotte-logo.webp" width="84" height="96" alt="" />
      </div>
      <p className="yz-stamp__rule">{card.rule}</p>
      <ol className="yz-stamp__grid" aria-label={`${card.filled} passages sur ${card.total}`}>
        {stamps.map((done, i) => (
          <li
            key={i}
            className={done ? 'is-done' : i === card.total - 1 ? 'is-reward' : ''}
            aria-hidden="true"
          >
            {done ? <Check size={16} strokeWidth={3} /> : <Gift size={16} strokeWidth={2.2} />}
          </li>
        ))}
      </ol>
      <p className="yz-stamp__status yz-mono">
        <span className="yz-stamp__pulse" aria-hidden="true" />
        {card.status}
      </p>
    </div>
  )
}

export default function ProLoyalty() {
  return (
    <section className="yz-section yz-light yz-loyalty" aria-labelledby="yz-loyalty-title">
      <div className="yz-container">
        <div className="yz-loyalty__top">
          <SectionHead
            index={PRO_LOYALTY.index}
            eyebrow={PRO_LOYALTY.eyebrow}
            title={PRO_LOYALTY.title}
            titleId="yz-loyalty-title"
          />
          <StampCard card={PRO_LOYALTY.card} />
        </div>

        <CheckColumns columns={PRO_LOYALTY.columns} />

        <p className="yz-loyalty__punch">
          <span className="yz-accent">{PRO_LOYALTY.punchline}</span>
        </p>
      </div>
    </section>
  )
}
