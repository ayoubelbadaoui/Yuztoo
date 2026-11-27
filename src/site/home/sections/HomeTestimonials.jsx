import { Coffee, ShoppingBasket, Waves } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { HOME_TESTIMONIALS } from '../homeContent.js'
import { bt } from '../../components/Brand.jsx'

const TRADE_ICONS = { coffee: Coffee, waves: Waves, basket: ShoppingBasket }

export default function HomeTestimonials() {
  const { quotes, question } = HOME_TESTIMONIALS
  const total = String(quotes.length).padStart(2, '0')

  return (
    <section className="yz-section yz-light yz-voices" aria-labelledby="yz-voices-title">
      <div className="yz-container">
        <SectionHead
          index={HOME_TESTIMONIALS.index}
          eyebrow={HOME_TESTIMONIALS.eyebrow}
          title={HOME_TESTIMONIALS.title}
          lead={HOME_TESTIMONIALS.lead}
          titleId="yz-voices-title"
        />

        <ul className="yz-grid yz-voices__grid">
          {quotes.map((item, i) => {
            const Icon = TRADE_ICONS[item.icon]
            return (
              <li
                key={item.id}
                className="yz-cell yz-voice"
                data-reveal
                style={{ '--d': `${i * 0.08}s` }}
              >
                <figure>
                  <p className="yz-voice__q yz-mono" aria-hidden="true">
                    <span>Q.</span>
                    {question}
                    <em>
                      {String(i + 1).padStart(2, '0')}/{total}
                    </em>
                  </p>
                  <blockquote className="yz-voice__quote">
                    <p>{bt(item.quote)}</p>
                  </blockquote>
                  <figcaption className="yz-voice__who">
                    <span className="yz-voice__r" aria-hidden="true">
                      <Icon size={18} strokeWidth={2} />
                    </span>
                    <span>
                      <strong>{bt(item.author)}</strong>
                      <span className="yz-mono">{bt(item.role)}</span>
                    </span>
                  </figcaption>
                </figure>
              </li>
            )
          })}
        </ul>
      </div>
    </section>
  )
}
