import { ArrowRight } from 'lucide-react'
import { bt } from './Brand.jsx'

/** Mid-page call to action: one line of copy and a jump to the page's form. */
export default function CtaStrip({ cta }) {
  return (
    <aside className="yz-dark yz-ctastrip" aria-label={cta.title}>
      <div className="yz-container yz-ctastrip__inner" data-reveal>
        <div>
          <p className="yz-ctastrip__title">{bt(cta.title)}</p>
          <p className="yz-ctastrip__text">{bt(cta.text)}</p>
        </div>
        <a className="yz-btn yz-btn--primary" href={cta.href}>
          {bt(cta.label)}
          <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
        </a>
      </div>
    </aside>
  )
}
