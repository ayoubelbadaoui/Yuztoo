import { ArrowRight } from 'lucide-react'
import { bt } from './Brand.jsx'

export default function SectionStrip({ text, cta, href }) {
  return (
    <div className="yz-strip" data-reveal>
      <p className="yz-strip__text">{bt(text)}</p>
      <a className="yz-btn yz-btn--ghost" href={href}>
        {cta}
        <ArrowRight size={16} strokeWidth={2.4} aria-hidden="true" />
      </a>
    </div>
  )
}
