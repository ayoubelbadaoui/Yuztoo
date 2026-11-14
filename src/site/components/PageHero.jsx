import { ArrowDown, ArrowRight, Check } from 'lucide-react'
import Breadcrumb from './Breadcrumb.jsx'
import SiteAmbient from './SiteAmbient.jsx'

/**
 * Inner-page hero. `hero`: { crumb, badge, titleLead, titleAccent, titleEnd,
 * intro, primaryCta?, secondaryCta?, checks? }. The visual is passed as children.
 */
export default function PageHero({ hero, BadgeIcon, className = '', children }) {
  return (
    <section className={`yz-hero yz-prohero ${className}`} aria-labelledby="yz-page-title">
      <SiteAmbient variant="grid" />

      <div className="yz-hero__inner">
        <div className="yz-hero__copy">
          <Breadcrumb current={hero.crumb} />

          <p className="yz-badge">
            {BadgeIcon ? <BadgeIcon size={14} strokeWidth={2.4} aria-hidden="true" /> : null}
            {hero.badge}
          </p>

          <h1 id="yz-page-title" className="yz-hero__title">
            {hero.titleLead} <span className="yz-accent">{hero.titleAccent}</span>
            {hero.titleEnd ? (
              <>
                {' '}
                <span className="yz-hero__title-end">{hero.titleEnd}</span>
              </>
            ) : null}
          </h1>

          <p className="yz-hero__lead">{hero.intro}</p>

          {hero.primaryCta || hero.secondaryCta ? (
            <div className="yz-hero__actions">
              {hero.primaryCta ? (
                <a className="yz-btn yz-btn--primary" href={hero.primaryCta.href}>
                  {hero.primaryCta.label}
                  <ArrowRight size={18} strokeWidth={2.4} aria-hidden="true" />
                </a>
              ) : null}
              {hero.secondaryCta ? (
                <a className="yz-link" href={hero.secondaryCta.href}>
                  <ArrowDown size={14} strokeWidth={2.6} aria-hidden="true" />
                  {hero.secondaryCta.label}
                </a>
              ) : null}
            </div>
          ) : null}

          {hero.checks ? (
            <ul className="yz-prohero__checks">
              {hero.checks.map((check) => (
                <li key={check}>
                  <Check size={15} strokeWidth={3} aria-hidden="true" />
                  {check}
                </li>
              ))}
            </ul>
          ) : null}
        </div>

        <div className="yz-prohero__visual">{children}</div>
      </div>
    </section>
  )
}
