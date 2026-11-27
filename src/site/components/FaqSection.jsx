import { Plus } from 'lucide-react'
import SectionHead from './SectionHead.jsx'
import { bt } from './Brand.jsx'

export default function FaqSection({ faq, id = 'faq' }) {
  return (
    <section className="yz-section yz-light yz-faq" aria-labelledby={`${id}-title`}>
      <div className="yz-container yz-faq__layout">
        <SectionHead index={faq.index} eyebrow={faq.eyebrow} title={faq.title} titleId={`${id}-title`} />

        <div className="yz-faq__list">
          {faq.items.map((item, i) => (
            <details key={item.id} className="yz-faq__item" open={i === 0}>
              <summary>
                <span className="yz-faq__num yz-mono" aria-hidden="true">
                  {String(i + 1).padStart(2, '0')}
                </span>
                <h3 className="yz-faq__q">{bt(item.question)}</h3>
                <span className="yz-faq__toggle" aria-hidden="true">
                  <Plus size={18} strokeWidth={2.4} />
                </span>
              </summary>
              <p className="yz-faq__a">{bt(item.answer)}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  )
}
