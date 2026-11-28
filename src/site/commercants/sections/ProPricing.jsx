import { ArrowRight, Check, Sparkles } from 'lucide-react'
import SectionHead from '../../components/SectionHead.jsx'
import { bt } from '../../components/Brand.jsx'
import { PRO_PRICING } from '../commercantsContent.js'
import DevNote from '../../components/DevNote.jsx'

function Plan({ plan }) {
  return (
    <article className={`yz-plan${plan.featured ? ' is-featured' : ''}`} data-reveal>
      <header className="yz-plan__head">
        <h3 className="yz-plan__name">{plan.name}</h3>
        <span className="yz-plan__saving">{plan.saving}</span>
      </header>

      <p className="yz-plan__normal">
        <span className="yz-sr-only">Tarif normal : </span>
        <s>
          {plan.normal}
          {plan.period}
        </s>
      </p>

      <p className="yz-plan__price">
        <span className="yz-sr-only">Offre pionniers : </span>
        <strong>{plan.pioneer}</strong>
        <span>{plan.period}</span>
      </p>

      <p className="yz-plan__pioneer yz-mono">
        <Sparkles size={14} strokeWidth={2.4} aria-hidden="true" />
        {PRO_PRICING.pioneerLabel}
      </p>

      {plan.features.length ? (
        <ul className="yz-plan__features">
          {plan.features.map((feature) => (
            <li key={feature}>
              <Check size={16} strokeWidth={3} aria-hidden="true" />
              {bt(feature)}
            </li>
          ))}
        </ul>
      ) : null}

      <a className={`yz-btn ${plan.featured ? 'yz-btn--primary' : 'yz-btn--ghost'} yz-plan__cta`} href={plan.cta.href}>
        {plan.cta.label}
        <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
      </a>
    </article>
  )
}

export default function ProPricing() {
  return (
    <section id="tarifs" className="yz-section yz-dark yz-pricing" aria-labelledby="yz-pricing-title">
      <div className="yz-container">
        <SectionHead
          index={PRO_PRICING.index}
          eyebrow={PRO_PRICING.eyebrow}
          title={PRO_PRICING.title}
          lead={PRO_PRICING.lead}
          titleId="yz-pricing-title"
        />

        <DevNote id="pricing" place="inline" />

        <div className="yz-pricing__plans">
          {PRO_PRICING.plans.map((plan) => (
            <Plan key={plan.id} plan={plan} />
          ))}
        </div>

        <ul className="yz-pricing__conditions">
          {PRO_PRICING.conditions.map((condition) => (
            <li key={condition}>{bt(condition)}</li>
          ))}
        </ul>
      </div>
    </section>
  )
}
