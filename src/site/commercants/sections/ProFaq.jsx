import { Plus } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { PRO_FAQ } from '../commercantsContent.js'

export default function ProFaq() {
  return (
    <section className="yz-section yz-light yz-faq" aria-labelledby="yz-faq-title">
      <div className="yz-container yz-faq__layout">
        <SectionHead
          index={PRO_FAQ.index}
          eyebrow={PRO_FAQ.eyebrow}
          title={PRO_FAQ.title}
          titleId="yz-faq-title"
        />

        <div className="yz-faq__list">
          {PRO_FAQ.items.map((item, i) => (
            <details key={item.id} className="yz-faq__item" open={i === 0}>
              <summary>
                <span className="yz-faq__num yz-mono" aria-hidden="true">
                  {String(i + 1).padStart(2, '0')}
                </span>
                <h3 className="yz-faq__q">{item.question}</h3>
                <span className="yz-faq__toggle" aria-hidden="true">
                  <Plus size={18} strokeWidth={2.4} />
                </span>
              </summary>
              <p className="yz-faq__a">{item.answer}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  )
}
